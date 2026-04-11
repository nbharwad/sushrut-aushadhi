"""
Retry Strategy with Exponential Backoff
========================================
Implements retry logic as defined in implementation.md Section 6.2:

- Exponential backoff with jitter
- Retry budgets to prevent cascade failures
- Configurable retry policies per operation type
"""

from __future__ import annotations

import asyncio
import logging
import random
import time
from dataclasses import dataclass, field
from enum import Enum
from functools import wraps
from typing import Callable, Optional, Type, TypeVar, Generic

import structlog

logger = structlog.get_logger(component="retry")


class RetryStrategy(str, Enum):
    """Retry strategies"""
    EXPONENTIAL = "exponential"
    LINEAR = "linear"
    CONSTANT = "constant"
    FIBONACCI = "fibonacci"


@dataclass(frozen=True)
class RetryConfig:
    """Retry configuration"""
    max_retries: int = 3
    initial_delay_ms: int = 100
    max_delay_ms: int = 10000
    exponential_base: float = 2.0
    jitter_factor: float = 0.1
    strategy: RetryStrategy = RetryStrategy.EXPONENTIAL
    retryable_exceptions: tuple = field(default_factory=lambda: (Exception,))
    budget_per_minute: int = 60


@dataclass
class RetryStats:
    """Retry statistics for monitoring"""
    total_attempts: int = 0
    successful_retries: int = 0
    failed_retries: int = 0
    budget_exhausted: int = 0
    
    def record_attempt(self):
        self.total_attempts += 1
    
    def record_success(self):
        self.successful_retries += 1
    
    def record_failure(self):
        self.failed_retries += 1
    
    def record_budget_exhausted(self):
        self.budget_exhausted += 1


class RetryBudget:
    """Token bucket for retry budget limiting"""
    
    def __init__(self, tokens_per_minute: int = 60):
        self.tokens_per_minute = tokens_per_minute
        self.tokens = float(tokens_per_minute)
        self.last_refill = time.monotonic()
    
    def try_acquire(self) -> bool:
        """Try to acquire a retry token"""
        now = time.monotonic()
        elapsed = now - self.last_refill
        
        if elapsed >= 60:
            self.tokens = min(self.tokens_per_minute, self.tokens + elapsed / 60 * self.tokens_per_minute)
            self.last_refill = now
        
        if self.tokens >= 1:
            self.tokens -= 1
            return True
        
        return False


class RetryContext:
    """Context for retry operations"""
    
    def __init__(
        self,
        config: RetryConfig,
        operation_name: str,
        budget: Optional[RetryBudget] = None,
    ):
        self.config = config
        self.operation_name = operation_name
        self.budget = budget or RetryBudget(config.budget_per_minute)
        self.attempt = 0
        self.start_time = time.monotonic()
    
    @property
    def should_retry(self) -> bool:
        return self.attempt < self.config.max_retries
    
    @property
    def elapsed_ms(self) -> float:
        return (time.monotonic() - self.start_time) * 1000
    
    def calculate_delay(self) -> float:
        """Calculate delay with exponential backoff and jitter"""
        config = self.config
        
        if config.strategy == RetryStrategy.EXPONENTIAL:
            delay = config.initial_delay_ms * (config.exponential_base ** self.attempt)
        elif config.strategy == RetryStrategy.LINEAR:
            delay = config.initial_delay_ms * (self.attempt + 1)
        elif config.strategy == RetryStrategy.FIBONACCI:
            delay = config.initial_delay_ms * fibonacci(self.attempt + 1)
        else:
            delay = config.initial_delay_ms
        
        delay = min(delay, config.max_delay_ms)
        
        jitter = delay * config.jitter_factor * random.uniform(-1, 1)
        delay = max(0, delay + jitter)
        
        return delay


def fibonacci(n: int) -> int:
    """Calculate nth Fibonacci number"""
    if n <= 1:
        return 1
    a, b = 1, 1
    for _ in range(n - 1):
        a, b = b, a + b
    return b


async def retry_async(
    func: Callable,
    *args,
    config: Optional[RetryConfig] = None,
    operation_name: Optional[str] = None,
    **kwargs,
):
    """
    Retry async function with exponential backoff.
    
    Usage:
        result = await retry_async(
            fragile_function,
            config=RetryConfig(max_retries=3),
            operation_name="fetch_user_data"
        )
    """
    config = config or RetryConfig()
    operation_name = operation_name or func.__name__
    ctx = RetryContext(config, operation_name)
    
    last_exception = None
    
    while ctx.should_retry:
        if not ctx.budget.try_acquire():
            logger.warning(
                "retry_budget_exhausted",
                operation=operation_name,
                attempts=ctx.attempt,
            )
            ctx.budget.record_budget_exhausted()
            break
        
        ctx.attempt += 1
        ctx.record_attempt()
        
        try:
            result = await func(*args, **kwargs)
            ctx.record_success()
            
            logger.info(
                "retry_succeeded",
                operation=operation_name,
                attempts=ctx.attempt,
                elapsed_ms=round(ctx.elapsed_ms, 2),
            )
            
            return result
            
        except config.retryable_exceptions as e:
            last_exception = e
            ctx.record_failure()
            
            if ctx.should_retry:
                delay = ctx.calculate_delay()
                
                logger.warning(
                    "retry_attempt",
                    operation=operation_name,
                    attempt=ctx.attempt,
                    max_retries=config.max_retries,
                    delay_ms=round(delay, 2),
                    error=str(e),
                )
                
                await asyncio.sleep(delay / 1000)
            else:
                logger.error(
                    "retry_exhausted",
                    operation=operation_name,
                    total_attempts=ctx.attempt,
                    error=str(e),
                )
    
    raise last_exception


def retry_sync(
    func: Callable,
    *args,
    config: Optional[RetryConfig] = None,
    operation_name: Optional[str] = None,
    **kwargs,
):
    """
    Retry sync function with exponential backoff.
    
    Usage:
        result = retry_sync(
            fragile_function,
            config=RetryConfig(max_retries=3),
            operation_name="fetch_data"
        )
    """
    config = config or RetryConfig()
    operation_name = operation_name or func.__name__
    ctx = RetryContext(config, operation_name)
    
    last_exception = None
    
    while ctx.should_retry:
        if not ctx.budget.try_acquire():
            logger.warning(
                "retry_budget_exhausted",
                operation=operation_name,
                attempts=ctx.attempt,
            )
            break
        
        ctx.attempt += 1
        ctx.record_attempt()
        
        try:
            result = func(*args, **kwargs)
            ctx.record_success()
            
            logger.info(
                "retry_succeeded",
                operation=operation_name,
                attempts=ctx.attempt,
            )
            
            return result
            
        except config.retryable_exceptions as e:
            last_exception = e
            ctx.record_failure()
            
            if ctx.should_retry:
                delay = ctx.calculate_delay()
                
                logger.warning(
                    "retry_attempt",
                    operation=operation_name,
                    attempt=ctx.attempt,
                    delay_ms=round(delay, 2),
                )
                
                time.sleep(delay / 1000)
    
    raise last_exception


def with_retry(config: Optional[RetryConfig] = None, operation_name: Optional[str] = None):
    """
    Decorator for retry logic.
    
    Usage:
        @with_retry(config=RetryConfig(max_retries=3), operation_name="api_call")
        async def fetch_data():
            ...
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            return await retry_async(
                func, *args, config=config, operation_name=operation_name, **kwargs
            )
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            return retry_sync(
                func, *args, config=config, operation_name=operation_name, **kwargs
            )
        
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper
    
    return decorator


STATS = RetryStats()


def get_stats() -> RetryStats:
    """Get retry statistics"""
    return STATS