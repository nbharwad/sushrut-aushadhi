package com.recsys.flink.useremb;

import com.recsys.flink.useremb.functions.UserEmbeddingProcessFunction;
import com.recsys.flink.useremb.sink.MilvusSink;
import com.recsys.flink.useremb.sink.RedisSink;
import com.recsys.flink.useremb.types.SessionUpdateEvent;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.ProcessFunction;
import org.apache.flink.util.Collector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;

public class UserEmbeddingJob {

    private static final Logger LOG = LoggerFactory.getLogger(UserEmbeddingJob.class);

    public static void main(String[] args) throws Exception {
        UserEmbeddingConfig config = UserEmbeddingConfig.fromEnvironment();

        LOG.info("Starting User Embedding Job");
        LOG.info("Kafka: {} / {}", config.getKafkaBootstrapServers(), config.getKafkaTopic());
        LOG.info("Model: {} (dim={})", config.getModelPath(), config.getEmbeddingDim());
        LOG.info("Window: {}min size, {}min slide", config.getWindowSizeMinutes(), config.getWindowSlideMinutes());

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.enableCheckpointing(config.getCheckpointIntervalMs());

        KafkaSource<String> kafkaSource = KafkaSource.<String>builder()
                .setBootstrapServers(config.getKafkaBootstrapServers())
                .setTopics(config.getKafkaTopic())
                .setGroupId(config.getKafkaGroupId())
                .setStartingOffsets(OffsetsInitializer.committedOffsets())
                .setDeserializer(new SimpleStringSchema())
                .build();

        WatermarkStrategy<String> watermarkStrategy = WatermarkStrategy
                .<String>forBoundedOutOfOrderness(Duration.ofMinutes(2))
                .withTimestampAssigner((event, ts) -> System.currentTimeMillis());

        DataStream<String> rawEvents = env.fromSource(kafkaSource, watermarkStrategy, "Session Features");
        DataStream<SessionUpdateEvent> events = rawEvents
                .process(new ProcessFunction<String, SessionUpdateEvent>() {
                    @Override
                    public void process(String value, Context ctx, Collector<SessionUpdateEvent> out) {
                        try {
                            out.collect(SessionUpdateEvent.fromJson(value));
                        } catch (Exception e) {
                            LOG.warn("Failed to parse session update: {}", e.getMessage());
                        }
                    }
                })
                .name("Parse Session Updates");

        DataStream<UserEmbedding> embeddings = events
                .keyBy(SessionUpdateEvent::getUserId)
                .process(new UserEmbeddingProcessFunction(config))
                .name("User Embedding Computation")
                .uid("user-embedding-computation");

        embeddings
                .sinkFor(new RedisSink(config))
                .name("Redis Sink")
                .uid("redis-sink-user-emb");

        embeddings
                .sinkFor(new MilvusSink(config))
                .name("Milvus Sink")
                .uid("milvus-sink-user-emb");

        env.execute("User Embedding Job");
    }
}