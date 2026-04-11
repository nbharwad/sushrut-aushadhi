package com.recsys.flink.onboarding;

public class OnboardingConfig {

    private String kafkaTopic = "item-onboarding";
    private String milvusCollection = "items";
    private String redisKeyPrefix = "is:";
    private int embeddingDim = 128;

    public String getKafkaTopic() { return kafkaTopic; }
    public void setKafkaTopic(String kafkaTopic) { this.kafkaTopic = kafkaTopic; }

    public String getMilvusCollection() { return milvusCollection; }
    public void setMilvusCollection(String milvusCollection) { this.milvusCollection = milvusCollection; }

    public String getRedisKeyPrefix() { return redisKeyPrefix; }
    public void setRedisKeyPrefix(String redisKeyPrefix) { this.redisKeyPrefix = redisKeyPrefix; }

    public int getEmbeddingDim() { return embeddingDim; }
    public void setEmbeddingDim(int embeddingDim) { this.embeddingDim = embeddingDim; }
}