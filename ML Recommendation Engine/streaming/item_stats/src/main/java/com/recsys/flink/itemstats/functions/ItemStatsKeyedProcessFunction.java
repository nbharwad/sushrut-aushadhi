package com.recsys.flink.itemstats.functions;

import com.recsys.flink.itemstats.ItemStatsConfig;
import com.recsys.flink.itemstats.types.ItemEvent.ItemStats;
import org.apache.flink.api.common.state.ListState;
import org.apache.flink.api.common.state.ListStateDescriptor;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.streaming.api.functions.KeyedProcessFunction;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.util.Collector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class ItemStatsKeyedProcessFunction extends KeyedProcessFunction<String, ItemEvent, ItemStats> {

    private static final Logger LOG = LoggerFactory.getLogger(ItemStatsKeyedProcessFunction.class);

    private final ItemStatsConfig config;
    private transient ListState<ItemEvent> windowEvents;

    public ItemStatsKeyedProcessFunction(ItemStatsConfig config) {
        this.config = config;
    }

    @Override
    public void open(Configuration parameters) {
        windowEvents = getRuntimeContext().getListState(
                new ListStateDescriptor<>("window-events", TypeInformation.of(ItemEvent.class))
        );
    }

    @Override
    public void processElement(ItemEvent event, Context ctx, Collector<ItemStats> out) throws Exception {
        windowEvents.add(event);

        TimeWindow window = ctx.window();
        long windowEnd = window.getEnd();

        List<ItemEvent> events = new ArrayList<>();
        Iterator<ItemEvent> iterator = windowEvents.get().iterator();
        while (iterator.hasNext()) {
            events.add(iterator.next());
        }

        ItemStats stats = new ItemStats(event.getItemId());
        stats.setWindowEndMs(windowEnd);

        for (ItemEvent e : events) {
            String eventType = e.getEventType();
            switch (eventType) {
                case "VIEW":
                    stats.incrementView();
                    break;
                case "CLICK":
                    stats.incrementClick();
                    break;
                case "ADD_TO_CART":
                    stats.incrementCartAdd();
                    break;
                case "PURCHASE":
                    stats.incrementPurchase();
                    break;
            }
        }

        out.collect(stats);

        windowEvents.clear();
    }
}