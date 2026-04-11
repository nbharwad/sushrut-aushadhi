package com.recsys.flink.itemstats;

import com.recsys.flink.itemstats.functions.ItemStatsWindowFunction;
import com.recsys.flink.itemstats.functions.ItemStatsKeyedProcessFunction;
import com.recsys.flink.itemstats.sink.ItemStatsRedisSink;
import com.recsys.flink.itemstats.types.ItemEvent;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.connector.kafka.sink.KafkaRecordSerialization;
import org.apache.flink.connector.kafka.sink.KafkaSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.datastream.WindowedStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.ProcessFunction;
import org.apache.flink.streaming.api.functions.windowing.ProcessAllWindowFunction;
import org.apache.flink.streaming.api.windowing.assigners.SlidingEventTimeWindows;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.util.Collector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;

public class ItemStatsJob {

    private static final Logger LOG = LoggerFactory.getLogger(ItemStatsJob.class);

    public static void main(String[] args) throws Exception {
        ItemStatsConfig config = ItemStatsConfig.fromEnvironment();

        LOG.info("Starting Item Stats Job");
        LOG.info("Kafka: {} / {}", config.getKafkaBootstrapServers(), config.getKafkaTopic());
        LOG.info("Redis: {}:{}", config.getRedisHost(), config.getRedisPort());
        LOG.info("Window: {}h size, {}m slide", config.getWindowSizeHours(), config.getWindowSlideMinutes());
        LOG.info("Parallelism: {}", config.getParallelism());

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        env.enableCheckpointing(config.getCheckpointIntervalMs());
        env.getCheckpointConfig().setMinPauseBetweenCheckpoints(10000);
        env.getCheckpointConfig().setTolerableCheckpointFailureCount(1);
        env.getCheckpointConfig().setMaxConcurrentCheckpoints(1);

        KafkaSource<String> kafkaSource = KafkaSource.<String>builder()
                .setBootstrapServers(config.getKafkaBootstrapServers())
                .setTopics(config.getKafkaTopic())
                .setGroupId(config.getKafkaGroupId())
                .setStartingOffsets(OffsetsInitializer.committedOffsets())
                .setDeserializer(new SimpleStringSchema())
                .build();

        WatermarkStrategy<String> watermarkStrategy = WatermarkStrategy
                .<String>forBoundedOutOfOrderness(config.getMaxOutOfOrderness())
                .withTimestampAssigner((event, timestamp) -> {
                    try {
                        ItemEvent itemEvent = ItemEvent.fromJson(event);
                        return itemEvent.getTimestampMs();
                    } catch (Exception e) {
                        return System.currentTimeMillis();
                    }
                });

        DataStream<String> rawEvents = env.fromSource(
                kafkaSource,
                watermarkStrategy,
                "Kafka Source - User Events"
        );

        DataStream<ItemEvent> events = rawEvents
                .process(new ProcessFunction<String, ItemEvent>() {
                    @Override
                    public void process(String value, Context ctx, Collector<ItemEvent> out) {
                        try {
                            out.collect(ItemEvent.fromJson(value));
                        } catch (Exception e) {
                            LOG.warn("Failed to parse event: {}", e.getMessage());
                        }
                    }
                })
                .name("Parse Item Events")
                .uid("parse-item-events");

        WindowedStream<ItemEvent, String, TimeWindow> windowedEvents = events
                .keyBy(ItemEvent::getItemId)
                .window(SlidingEventTimeWindows.of(
                        config.getWindowSize(),
                        config.getWindowSlide()
                ));

        DataStream<ItemStats> stats = windowedEvents
                .process(new ItemStatsKeyedProcessFunction(config))
                .name("Item Stats Aggregation")
                .uid("item-stats-aggregation");

        stats
                .sinkFor(new ItemStatsRedisSink(config))
                .name("Redis Sink - Item Stats")
                .uid("redis-sink-item-stats");

        env.execute("Item Stats Job");
    }
}