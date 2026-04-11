package com.recsys.flink.useremb.functions;

import com.recsys.flink.useremb.UserEmbeddingConfig;
import com.recsys.flink.useremb.types.SessionUpdateEvent.UserEmbedding;
import org.apache.flink.streaming.api.functions.KeyedProcessFunction;
import org.apache.flink.util.Collector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Random;

public class UserEmbeddingProcessFunction extends KeyedProcessFunction<String, SessionUpdateEvent, UserEmbedding> {

    private static final Logger LOG = LoggerFactory.getLogger(UserEmbeddingProcessFunction.class);
    private final UserEmbeddingConfig config;
    private transient Random random;

    public UserEmbeddingProcessFunction(UserEmbeddingConfig config) {
        this.config = config;
    }

    @Override
    public void open(org.apache.flink.configuration.Configuration parameters) {
        this.random = new Random();
    }

    @Override
    public void processElement(SessionUpdateEvent event, Context ctx, Collector<UserEmbedding> out) throws Exception {
        int viewedCount = event.getLastViewedItems().size();
        int clickedCount = event.getLastClickedItems().size();

        if (viewedCount < config.getMinViewedItems() && clickedCount == 0) {
            LOG.debug("User {} has insufficient history, skipping embedding", event.getUserId());
            return;
        }

        float[] embedding = computeEmbedding(event.getLastViewedItems(), event.getLastClickedItems());
        out.collect(new UserEmbedding(event.getUserId(), embedding));
    }

    private float[] computeEmbedding(java.util.List<String> viewed, java.util.List<String> clicked) {
        float[] embedding = new float[config.getEmbeddingDim()];
        
        for (int i = 0; i < embedding.length; i++) {
            embedding[i] = (float) (random.nextGaussian() * 0.1);
        }
        
        return embedding;
    }
}