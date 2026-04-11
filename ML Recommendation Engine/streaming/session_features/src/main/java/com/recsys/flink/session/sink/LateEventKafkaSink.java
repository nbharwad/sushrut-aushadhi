package com.recsys.flink.session.sink;

import com.recsys.flink.session.SessionFeatureConfig;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.functions.sink.RichSinkFunction;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

public class LateEventKafkaSink extends RichSinkFunction<String> {

    private static final Logger LOG = LoggerFactory.getLogger(LateEventKafkaSink.class);

    private final SessionFeatureConfig config;
    private transient KafkaProducer<String, String> kafkaProducer;

    public LateEventKafkaSink(SessionFeatureConfig config) {
        this.config = config;
    }

    @Override
    public void open(Configuration parameters) {
        Map<String, Object> producerProps = new HashMap<>();
        producerProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, config.getKafkaBootstrapServers());
        producerProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        producerProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        producerProps.put(ProducerConfig.ACKS_CONFIG, "all");
        producerProps.put(ProducerConfig.RETRIES_CONFIG, 3);
        producerProps.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384);
        producerProps.put(ProducerConfig.LINGER_MS_CONFIG, 1);

        kafkaProducer = new KafkaProducer<>(producerProps);

        LOG.info("Late event Kafka producer connected to {}", config.getKafkaBootstrapServers());
    }

    @Override
    public void invoke(String value, Context context) {
        try {
            String topic = "user-events-late";
            ProducerRecord<String, String> record = new ProducerRecord<>(topic, value);
            kafkaProducer.send(record);
            LOG.debug("Late event sent to {}", topic);
        } catch (Exception e) {
            LOG.error("Failed to send late event to Kafka: {}", e.getMessage(), e);
            throw new RuntimeException("Late event Kafka send failed", e);
        }
    }

    @Override
    public void close() {
        if (kafkaProducer != null) {
            kafkaProducer.flush();
            kafkaProducer.close();
            LOG.info("Late event Kafka producer closed");
        }
    }
}