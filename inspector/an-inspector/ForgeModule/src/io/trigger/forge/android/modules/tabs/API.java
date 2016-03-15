package io.trigger.forge.android.modules.tabs;

import com.google.gson.JsonObject;

import java.util.WeakHashMap;

import io.trigger.forge.android.core.ForgeParam;
import io.trigger.forge.android.core.ForgeTask;

public class API {
	private static WeakHashMap<String, ModalView> modalViews = new WeakHashMap<String, ModalView>();
	
	public static void open(final ForgeTask task) {
		ModalView modal = new ModalView();
		modalViews.put(task.callid, modal);
		modal.openModal(task);
	}
	
	public static void executeJS(final ForgeTask task, @ForgeParam("modal") final String modal, @ForgeParam("script") final String script) {
		if (modalViews.get(modal) != null) {
			modalViews.get(modal).webViewProxy.stringByEvaluatingJavaScriptFromString(task, script); // TODO augh
		}
	}
	
	public static void close(final ForgeTask task, @ForgeParam("modal") final String modal) {
		if (modalViews.get(modal) != null) {
			modalViews.get(modal).close();
			task.success();
		}
	}

	public static void addButton(final ForgeTask task, @ForgeParam("modal") final String modal, @ForgeParam("params") final JsonObject params) {
		if (modalViews.get(modal) != null) {
			modalViews.get(modal).addButton(task, params);
		}
	}

	public static void removeButtons(final ForgeTask task, @ForgeParam("modal") final String modal) {
		if (modalViews.get(modal) != null) {
			modalViews.get(modal).removeButtons(task);
		}
	}
}
