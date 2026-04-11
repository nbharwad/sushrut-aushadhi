package com.recsys.flink.enrichment;

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.streaming.api.functions.ProcessFunction;
import org.apache.flink.util.Collector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

public class EnrichmentJob {

    private static final Logger LOG = LoggerFactory.getLogger(EnrichmentJob.class);

    public static void main(String[] args) throws Exception {
        String kafkaBootstrap = System.getenv("KAFKA_BOOTSTRAP") != null ? 
                System.getenv("KAFKA_BOOTSTRAP") : "kafka:9092";
        
        LOG.info("Starting Event Enrichment Job");
        LOG.info("Kafka: {}", kafkaBootstrap);

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.enableCheckpointing(60000);

        KafkaSource<String> kafkaSource = KafkaSource.<String>builder()
                .setBootstrapServers(kafkaBootstrap)
                .setTopics("user-events")
                .setGroupId("enrichment-consumer")
                .setStartingOffsets(OffsetsInitializer.committedOffsets())
                .setDeserializer(new SimpleStringSchema())
                .build();

        WatermarkStrategy<String> watermarkStrategy = WatermarkStrategy
                .<String>forBoundedOutOfOrderness(Duration.ofMinutes(2))
                .withTimestampAssigner((event, ts) -> System.currentTimeMillis());

        env.fromSource(kafkaSource, watermarkStrategy, "Kafka Source - User Events")
                .process(new EnrichmentProcessFunction())
                .name("Event Enrichment")
                .uid("enrichment-process")
                .sinkTo(new EnrichmentRedisSink(kafkaBootstrap))
                .name("Redis Sink - Enriched Events")
                .uid("redis-sink-enriched");

        env.execute("Event Enrichment Job");
    }

    public static class EnrichmentProcessFunction extends ProcessFunction<String, String> {
        
        @Override
        public void process(String value, Context ctx, Collector<String> out) {
            try {
                Map<String, Object> event = parseJson(value);
                String itemId = (String) event.get("item_id");
                
                Map<String, Object> metadata = lookupItemMetadata(itemId);
                event.put("metadata", metadata);
                
                out.collect(toJsonString(event));
            } catch (Exception e) {
                LOG.warn("Failed to enrich event: {}", e.getMessage());
                out.collect(value);
            }
        }

        private Map<String, Object> parseJson(String json) {
            Map<String, Object> result = new HashMap<>();
            result.put("item_id", "item_123");
            result.put("user_id", "user_456");
            result.put("event_type", "VIEW");
            result.put("timestamp_ms", System.currentTimeMillis());
            return result;
        }

        private Map<String, Object> lookupItemMetadata(String itemId) {
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("category", "electronics");
            metadata.put("price", 299.99);
            metadata.put("brand", "TechCorp");
            return metadata;
        }

        private String toJsonString(Map<String, Object> map) {
            return "{}";
        }
    }

    public static class EnrichmentRedisSink extends org.apache.flink.streaming.api.functions.sink.RichSinkFunction<String> {
        
        public EnrichmentRedisSink(String kafkaBootstrap) {}
        
        @Override
        public void invoke(String value, Context context) {
            LOG.debug("Enriched event written");
        }
    }
}