package com.recsys.flink.session.functions;

import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.streaming.api.functions.ProcessFunction;
import org.apache.flink.util.Collector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class LateEventFilterFunction extends ProcessFunction<String, String, String> {

    private static final Logger LOG = LoggerFactory.getLogger(LateEventFilterFunction.class);

    public static final OutputTag<String> LATE_EVENT_TAG = new OutputTag<>("late-events", TypeInformation.of(String.class));

    @Override
    public void process(String value, Context ctx, Collector<String> out) throws Exception {
        ctx.output(LATE_EVENT_TAG, value);
    }
}