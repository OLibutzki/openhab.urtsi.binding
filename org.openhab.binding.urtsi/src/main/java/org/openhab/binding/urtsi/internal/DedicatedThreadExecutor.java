package org.openhab.binding.urtsi.internal;

import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import org.eclipse.xtext.xbase.lib.Functions.Function1;

public class DedicatedThreadExecutor {
	private final ExecutorService executorService = Executors
			.newSingleThreadExecutor();

	public <T> Future<T> execute(final Function1<Object, T> closure) {
		return executorService.submit(new Callable<T>() {

			@Override
			public T call() throws Exception {
				return closure.apply(null);
			}
		});
	}

}
