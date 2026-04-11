package com.recsys.flink.session.types;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class UserEvent implements Serializable {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @JsonProperty("user_id")
    private String userId;

    @JsonProperty("session_id")
    private String sessionId;

    @JsonProperty("event_type")
    private String eventType;

    @JsonProperty("item_id")
    private String itemId;

    @JsonProperty("timestamp_ms")
    private long timestampMs;

    @JsonProperty("metadata")
    private Map<String, Object> metadata;

    public UserEvent() {
    }

    public UserEvent(String userId, String sessionId, String eventType, String itemId, long timestampMs) {
        this.userId = userId;
        this.sessionId = sessionId;
        this.eventType = eventType;
        this.itemId = itemId;
        this.timestampMs = timestampMs;
        this.metadata = new HashMap<>();
    }

    public static UserEvent fromJson(String json) throws JsonProcessingException {
        return MAPPER.readValue(json, UserEvent.class);
    }

    public String toJson() throws JsonProcessingException {
        return MAPPER.writeValueAsString(this);
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public String getItemId() {
        return itemId;
    }

    public void setItemId(String itemId) {
        this.itemId = itemId;
    }

    public long getTimestampMs() {
        return timestampMs;
    }

    public void setTimestampMs(long timestampMs) {
        this.timestampMs = timestampMs;
    }

    public Map<String, Object> getMetadata() {
        return metadata;
    }

    public void setMetadata(Map<String, Object> metadata) {
        this.metadata = metadata;
    }

    public Map<String, Object> toFeatureMap(String redisKeyPrefix) {
        Map<String, Object> result = new HashMap<>();
        result.put("user_id", userId);
        result.put("session_id", sessionId);
        result.put("event_type", eventType);
        result.put("item_id", itemId);
        result.put("timestamp_ms", timestampMs);
        result.put("redis_key", redisKeyPrefix + userId);
        if (metadata != null) {
            result.put("metadata", metadata);
        }
        return result;
    }

    public static class Builder {
        private String userId;
        private String sessionId;
        private String eventType;
        private String itemId;
        private long timestampMs = System.currentTimeMillis();
        private Map<String, Object> metadata = new HashMap<>();

        public Builder userId(String userId) {
            this.userId = userId;
            return this;
        }

        public Builder sessionId(String sessionId) {
            this.sessionId = sessionId;
            return this;
        }

        public Builder eventType(String eventType) {
            this.eventType = eventType;
            return this;
        }

        public Builder itemId(String itemId) {
            this.itemId = itemId;
            return this;
        }

        public Builder timestampMs(long timestampMs) {
            this.timestampMs = timestampMs;
            return this;
        }

        public Builder metadata(String key, Object value) {
            this.metadata.put(key, value);
            return this;
        }

        public UserEvent build() {
            return new UserEvent(userId, sessionId, eventType, itemId, timestampMs);
        }
    }
}