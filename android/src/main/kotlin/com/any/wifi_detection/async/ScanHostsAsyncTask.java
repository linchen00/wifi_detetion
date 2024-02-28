package com.any.wifi_detection.async;

import java.io.IOException;
import java.math.BigInteger;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import io.flutter.plugin.common.EventChannel;

import android.os.Handler;

public class ScanHostsAsyncTask {

    private final EventChannel.EventSink eventSink;

    public ScanHostsAsyncTask(EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }

    public void scanHosts(int ipv4, int cidr, int timeout,Handler mainHandler) {
        // 创建一个固定大小的线程池，其中包含多个线程
        ExecutorService executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());

        try {
            double hostBits = 32.0d - cidr;
            int netmask = (0xffffffff >> (32 - cidr)) << (32 - cidr);
            int numberOfHosts = (int) Math.pow(2.0d, hostBits) - 2;
            int firstAddr = (ipv4 & netmask) + 1;

            int SCAN_THREADS = (int) hostBits;
            int chunk = (int) Math.ceil((double) numberOfHosts / SCAN_THREADS);
            int previousStart = firstAddr;
            int previousStop = firstAddr + (chunk - 2);

            // 提交任务给线程池执行
            for (int i = 0; i < SCAN_THREADS; i++) {
                executor.execute(new ScanHostsRunnable(previousStart, previousStop, timeout, eventSink, mainHandler));
                previousStart = previousStop + 1;
                previousStop = previousStart + (chunk - 1);
            }

            // 关闭线程池
            executor.shutdown();
            // 等待线程池中的任务执行完成，最多等待5分钟
            if (!executor.awaitTermination(5, TimeUnit.MINUTES)) {
                // 如果超时，立即中断所有任务
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            // 捕获中断异常
            e.printStackTrace();
        }
    }

    static class ScanHostsRunnable implements Runnable {
        private final int start;
        private final int stop;
        private final int timeout;
        private final EventChannel.EventSink eventSink;

        private final Handler mainHandler;

        public ScanHostsRunnable(int start, int stop, int timeout, EventChannel.EventSink eventSink, Handler mainHandler) {
            this.start = start;
            this.stop = stop;
            this.timeout = timeout;
            this.eventSink = eventSink;
            this.mainHandler = mainHandler;
        }

        @Override
        public void run() {

            for (int i = start; i <= stop; i++) {
                try (Socket socket = new Socket()) {
                    socket.setTcpNoDelay(true);
                    byte[] bytes = BigInteger.valueOf(i).toByteArray();
                    socket.connect(new InetSocketAddress(InetAddress.getByAddress(bytes), 7), timeout);
                } catch (IOException ignored) {
                    // Connection failures aren't errors in this case.
                    // We want to fill up the ARP table with our connection attempts.
                } finally {
                    int finalI = i;
                    mainHandler.post(()->{
                        eventSink.success(finalI);
                    });

                    // Something's really wrong if we can't close the socket...

//                    eventSink.endOfStream();
                }
            }
        }
    }
}