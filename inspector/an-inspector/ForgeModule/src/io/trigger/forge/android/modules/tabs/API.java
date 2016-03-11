package io.trigger.forge.android.modules.tabs;

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
}
