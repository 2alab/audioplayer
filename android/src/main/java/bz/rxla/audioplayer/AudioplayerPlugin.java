package bz.rxla.audioplayer;

import android.content.Context;
import android.media.AudioManager;
import android.media.session.PlaybackState;
import android.net.Uri;
import android.os.Build;

import com.google.android.exoplayer2.ExoPlaybackException;
import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.ext.okhttp.OkHttpDataSourceFactory;
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory;
import com.google.android.exoplayer2.source.ExtractorMediaSource;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.upstream.DataSpec;
import com.google.android.exoplayer2.upstream.HttpDataSource;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import okhttp3.OkHttpClient;

/**
 * Android implementation for RaioPlayerPlugin
 */
public class AudioplayerPlugin implements MethodCallHandler {


    private static long HTTP_CONNECT_TIMEOUT_SECONDS = 10;
    private static long HTTP_READ_TIMEOUT_SECONDS = 10;

    private static final String ID = "ru.aalab/radioplayer";

    private final MethodChannel channel;
    private final AudioManager am;
    private SimpleExoPlayer mediaPlayer;
    private final Context context;

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), ID);
        channel.setMethodCallHandler(new AudioplayerPlugin(registrar, channel));
    }

    private AudioplayerPlugin(Registrar registrar, MethodChannel channel) {
        this.channel = channel;
        channel.setMethodCallHandler(this);
        context = registrar.context().getApplicationContext();
        this.am = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result response) {
        switch (call.method) {
            case "play":
                play(call.argument("url").toString());
                response.success(null);
                break;
            case "stop":
                stop();
                response.success(null);
                break;
            case "mute":
                Boolean muted = call.arguments();
                mute(muted);
                response.success(null);
                break;
            default:
                response.notImplemented();
        }
    }

    private void mute(Boolean muted) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.adjustStreamVolume(AudioManager.STREAM_MUSIC, muted ? AudioManager.ADJUST_MUTE : AudioManager.ADJUST_UNMUTE, 0);
        } else {
            am.setStreamMute(AudioManager.STREAM_MUSIC, muted);
        }
    }


    private void stop() {
        if (mediaPlayer != null) {
            mediaPlayer.stop();
            mediaPlayer.release();
            mediaPlayer = null;
            channel.invokeMethod("audio.onStop", null);
        }
    }


    private void play(String url) {
        channel.invokeMethod("audio.onBuffering", null);
        if (mediaPlayer == null) {
            mediaPlayer = ExoPlayerFactory.newSimpleInstance(context);
            OkHttpClient callFactory = new OkHttpClient.Builder()
                    .connectTimeout(HTTP_CONNECT_TIMEOUT_SECONDS,TimeUnit.SECONDS)
                    .readTimeout(HTTP_READ_TIMEOUT_SECONDS,TimeUnit.SECONDS)
                    .build();

            MediaSource source = new ExtractorMediaSource(Uri.parse(url), new OkHttpDataSourceFactory(callFactory, "ExoPlayer"), new DefaultExtractorsFactory(), null, null);
            mediaPlayer.prepare(source);
            mediaPlayer.setPlayWhenReady(true);

            mediaPlayer.addListener(new PlayerEventListener());
        } else {
            mediaPlayer.setPlayWhenReady(true);
        }
    }

    private class PlayerEventListener implements Player.EventListener {


        @Override
        public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
            if (playWhenReady && playbackState == Player.STATE_READY) {
                channel.invokeMethod("audio.onPlay", null);
            } else if (playWhenReady && playbackState == Player.STATE_BUFFERING) {
                channel.invokeMethod("audio.onBuffering", null);
            } else if (Player.STATE_ENDED == playbackState) {
                channel.invokeMethod("audio.onEnded", null);
                Log.v("RadioPlayer", "audio.onEnded ");
            }
        }

        @Override
        public void onPlayerError(ExoPlaybackException error) {
            if (error.type == ExoPlaybackException.TYPE_SOURCE) {
                IOException cause = error.getSourceException();
                if (cause instanceof HttpDataSource.HttpDataSourceException) {
                    HttpDataSource.HttpDataSourceException httpError = (HttpDataSource.HttpDataSourceException) cause;
                    // This is the request for which the error occurred.
                    DataSpec requestDataSpec = httpError.dataSpec;
                    channel.invokeMethod("audio.onEnded", null);
                    Log.v("RadioPlayer", "audio.onEnded");

                    mediaPlayer.stop();
                    mediaPlayer.release();
                    mediaPlayer = null;

                }
            }
        }


    }
}
