package org.lineageos.tv.audiooutput;

import android.app.Activity;
import android.content.Context;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckedTextView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.List;

public final class AudioOutputActivity extends Activity {
    private RouteAdapter mAdapter;
    private ListView mListView;
    private TextView mStatusView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        buildUi();
        refreshRoutes(getString(R.string.status_select_device));
    }

    @Override
    protected void onResume() {
        super.onResume();
        refreshRoutes(null);
    }

    private void buildUi() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER_HORIZONTAL);
        root.setPadding(dp(32), dp(28), dp(32), dp(24));
        root.setBackgroundColor(Color.rgb(16, 19, 24));

        TextView title = new TextView(this);
        title.setText(R.string.audio_output_title);
        title.setTextColor(Color.WHITE);
        title.setTextSize(28);
        title.setGravity(Gravity.START);
        title.setPadding(0, 0, 0, dp(8));
        root.addView(title, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        TextView summary = new TextView(this);
        summary.setText(R.string.audio_output_summary);
        summary.setTextColor(Color.rgb(189, 197, 208));
        summary.setTextSize(16);
        summary.setPadding(0, 0, 0, dp(18));
        root.addView(summary, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        mListView = new ListView(this);
        mListView.setChoiceMode(ListView.CHOICE_MODE_SINGLE);
        mListView.setItemsCanFocus(false);
        mListView.setSelector(android.R.drawable.list_selector_background);
        mListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                AudioRouteManager.RouteItem item = mAdapter.getItem(position);
                if (item != null) {
                    selectRoute(item);
                }
            }
        });
        root.addView(mListView, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1.0f));

        mStatusView = new TextView(this);
        mStatusView.setTextColor(Color.rgb(213, 218, 226));
        mStatusView.setTextSize(14);
        mStatusView.setMinLines(2);
        mStatusView.setGravity(Gravity.START | Gravity.CENTER_VERTICAL);
        mStatusView.setPadding(0, dp(12), 0, 0);
        root.addView(mStatusView, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        setContentView(root);
    }

    private void refreshRoutes(String status) {
        List<AudioRouteManager.RouteItem> routes = AudioRouteManager.getRouteItems(this);
        if (mAdapter == null) {
            mAdapter = new RouteAdapter(this, routes);
            mListView.setAdapter(mAdapter);
        } else {
            mAdapter.clear();
            mAdapter.addAll(routes);
            mAdapter.notifyDataSetChanged();
        }

        int checked = AudioRouteManager.findSavedRouteIndex(this, routes);
        if (checked >= 0) {
            mListView.setItemChecked(checked, true);
            mListView.setSelection(checked);
        }

        if (status != null) {
            mStatusView.setText(status);
        }
    }

    private void selectRoute(AudioRouteManager.RouteItem item) {
        AudioRouteManager.RouteResult result;
        if (item.isDefault()) {
            result = AudioRouteManager.clearPreferredDeviceForMedia(this);
            if (result.success) {
                AudioRouteManager.saveDefaultRoute(this);
            }
        } else {
            result = AudioRouteManager.setPreferredDeviceForMedia(this, item.device);
            if (result.success) {
                AudioRouteManager.saveRoute(this, item);
            }
        }

        String message = result.message;
        mStatusView.setText(message);
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
        refreshRoutes(message);
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    private final class RouteAdapter extends ArrayAdapter<AudioRouteManager.RouteItem> {
        RouteAdapter(Context context, List<AudioRouteManager.RouteItem> routes) {
            super(context, android.R.layout.simple_list_item_single_choice, routes);
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            View view = super.getView(position, convertView, parent);
            CheckedTextView text = (CheckedTextView) view.findViewById(android.R.id.text1);
            text.setTextColor(Color.WHITE);
            text.setTextSize(20);
            text.setGravity(Gravity.CENTER_VERTICAL);
            text.setMinHeight(dp(58));
            text.setPadding(dp(16), 0, dp(16), 0);
            return view;
        }
    }
}
