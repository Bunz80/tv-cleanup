package com.tvcleanup.turbo;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.pm.ApplicationInfo;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.widget.TextView;

/**
 * One press frees RAM on a TV: stops every app's background processes (the screen in front and system services
 * are left alone), then shows how much memory is free. No network, no data touched.
 */
public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        TextView text = new TextView(this);
        text.setGravity(Gravity.CENTER);
        text.setTextColor(Color.WHITE);
        text.setTextSize(34);
        text.setBackgroundColor(0xFF0B0F1A);
        text.setText("Turbo…");
        setContentView(text);
        new Thread(() -> {
            ActivityManager am = (ActivityManager) getSystemService(ACTIVITY_SERVICE);
            long before = availableMb(am);
            int stopped = 0;
            for (ApplicationInfo app : getPackageManager().getInstalledApplications(0)) {
                if (app.packageName.equals(getPackageName())) continue;
                am.killBackgroundProcesses(app.packageName);
                stopped++;
            }
            Runtime.getRuntime().gc();
            try {
                Thread.sleep(1200);
            } catch (InterruptedException ignored) {
            }
            long after = availableMb(am);
            long gained = Math.max(0, after - before);
            String done = "+" + gained + " MB\n\nRAM libera: " + after + " MB";
            Handler main = new Handler(Looper.getMainLooper());
            main.post(() -> text.setText(done));
            main.postDelayed(this::finish, 2500);
        }).start();
    }

    private static long availableMb(ActivityManager am) {
        ActivityManager.MemoryInfo info = new ActivityManager.MemoryInfo();
        am.getMemoryInfo(info);
        return info.availMem / (1024 * 1024);
    }
}
