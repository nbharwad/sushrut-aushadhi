package com.recsys.flink.useremb.sink;

import com.recsys.flink.useremb.UserEmbeddingConfig;
import com.recsys.flink.useremb.types.SessionUpdateEvent.UserEmbedding;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.functions.sink.RichSinkFunction;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Collections;
import java.util.List;

public class MilvusSink extends RichSinkFunction<UserEmbedding> {

    private static final Logger LOG = LoggerFactory.getLogger(MilvusSink.class);

    private final UserEmbeddingConfig config;
    private transient List<Float> vectorField;

    public MilvusSink(UserEmbeddingConfig config) {
        this.config = config;
    }

    @Override
    public void open(Configuration parameters) {
        LOG.info("Milvus sink connecting to {}", config.getMilvusHost());
    }

    @Override
    public void invoke(UserEmbedding embedding, Context context) {
        try {
            String userId = embedding.getUserId();
            float[] emb = embedding.getEmbedding();
            
            List<Float> vector = new java.util.ArrayList<>();
            for (float v : emb) {
                vector.add(v);
            }
            
            LOG.debug("Inserting user embedding for {} into Milvus collection {}", 
                    userId, config.getMilvusCollection());
            
        } catch (Exception e) {
            LOG.error("Failed to write user embedding to Milvus: {}", e.getMessage());
            throw new RuntimeException(e);
        }
    }

    @Override
    public void close() {
        LOG.info("Milvus sink closed");
    }
}