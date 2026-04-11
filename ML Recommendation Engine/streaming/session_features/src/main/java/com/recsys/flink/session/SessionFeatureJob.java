package com.recsys.flink.session;

import com.recsys.flink.session.functions.SessionFeatureProcessFunction;
import com.recsys.flink.session.functions.LateEventFilterFunction;
import com.recsys.flink.session.sink.RedisSink;
import com.recsys.flink.session.sink.LateEventKafkaSink;
import com.recsys.flink.session.types.UserEvent;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.connector.base.DeliveryGuarantee;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerialization;
import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.runtime.minicluster.MiniCluster;
import org.apache.flink.runtime.minicluster.MiniClusterConfiguration;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.ProcessFunction;
import org.apache.flink.util.Collector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

public class SessionFeatureJob {

    private static final Logger LOG = LoggerFactory.getLogger(SessionFeatureJob.class);

    public static void main(String[] args) throws Exception {
        SessionFeatureConfig config = SessionFeatureConfig.fromEnvironment();

        LOG.info("Starting Session Feature Job");
        LOG.info("Kafka: {} / {}", config.getKafkaBootstrapServers(), config.getKafkaTopic());
        LOG.info("Redis: {}:{}", config.getRedisHost(), config.getRedisPort());
        LOG.info("Session gap: {} minutes", config.getSessionGapMinutes());
        LOG.info("Checkpoint interval: {}ms", config.getCheckpointIntervalMs());
        LOG.info("Parallelism: {}", config.getParallelism());

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        env.enableCheckpointing(config.getCheckpointIntervalMs());
        env.getCheckpointConfig().setMinPauseBetweenCheckpoints(10000);
        env.getCheckpointConfig().setTolerableCheckpointFailureCount(1);
        env.getCheckpointConfig().setMaxConcurrentCheckpoints(1);

        env.getConfig().setAutoWatermarkInterval(config.getMaxOutOfOrdernessSeconds() * 1000L);

        KafkaSource<String> kafkaSource = KafkaSource.<String>builder()
                .setBootstrapServers(config.getKafkaBootstrapServers())
                .setTopics(config.getKafkaTopic())
                .setGroupId(config.getKafkaGroupId())
                .setStartingOffsets(OffsetsInitializer.committedOffsets())
                .setDeserializer(new SimpleStringSchema())
                .build();

        WatermarkStrategy<String> watermarkStrategy = WatermarkStrategy
                .<String>forBoundedOutOfOrderness(Duration.ofSeconds(config.getMaxOutOfOrdernessSeconds()))
                .withTimestampAssigner((event, timestamp) -> {
                    try {
                        UserEvent userEvent = UserEvent.fromJson(event);
                        return userEvent.getTimestampMs();
                    } catch (Exception e) {
                        return System.currentTimeMillis();
                    }
                })
                .withIdleness(Duration.ofMinutes(1));

        DataStream<String> rawEvents = env.fromSource(
                kafkaSource,
                watermarkStrategy,
                "Kafka Source - User Events"
        );

        DataStream<UserEvent> events = rawEvents
                .process(new ProcessFunction<String, UserEvent>() {
                    @Override
                    public void process(String value, Context ctx, Collector<UserEvent> out) {
                        try {
                            out.collect(UserEvent.fromJson(value));
                        } catch (Exception e) {
                            LOG.warn("Failed to parse event: {}", e.getMessage());
                        }
                    }
                })
                .name("Parse User Events")
                .uid("parse-user-events");

        DataStream<UserEvent> keyedEvents = events
                .keyBy(UserEvent::getUserId)
                .process(new SessionFeatureProcessFunction(config))
                .name("Session Feature Processing")
                .uid("session-feature-processing");

        SingleOutputStreamOperator<String> featureOutput = keyedEvents
                .process(new ProcessFunction<UserEvent, String>() {
                    @Override
                    public void process(UserEvent value, Context ctx, Collector<String> out) {
                        Map<String, Object> features = value.toFeatureMap(config.getRedisKeyPrefix());
                        out.collect(features.toString());
                    }
                })
                .name("Serialize Features")
                .uid("serialize-features");

        featureOutput
                .sinkFor(new RedisSink(config))
                .name("Redis Sink")
                .uid("redis-sink-session-features");

        DataStream<String> lateEvents = keyedEvents
                .getSideOutput(LateEventFilterFunction.LATE_EVENT_TAG)
                .sinkFor(new LateEventKafkaSink(config))
                .name("Late Events Kafka Sink")
                .uid("kafka-sink-late-events");

        env.execute("Session Feature Job");
    }

    public static StreamExecutionEnvironment createTestEnvironment(SessionFeatureConfig config) {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        env.enableCheckpointing(config.getCheckpointIntervalMs());
        env.setParallelism(config.getParallelism());

        return env;
    }

    public static void runLocal(SessionFeatureConfig config) throws Exception {
        MiniClusterConfiguration clusterConfig = new MiniClusterConfiguration();
        clusterConfig.setNumTaskManagers(1);
        clusterConfig.setNumSlots(config.getParallelism());

        try (MiniCluster cluster = new MiniCluster(clusterConfig)) {
            cluster.start();
            StreamExecutionEnvironment env = createTestEnvironment(config);
            cluster.executeAsync(env);
        }
    }
}