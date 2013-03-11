package org.openhab.binding.urtsi.internal;

import org.openhab.binding.urtsi.UrtsiBindingProvider;
import org.openhab.core.binding.AbstractBinding;
import org.openhab.core.types.Command;
import org.openhab.core.types.State;

public abstract class AbstractUrtsiBinding extends AbstractBinding<UrtsiBindingProvider> {


	protected void internalReceiveCommand(String itemName, Command command) {

	}
	
	protected void internalReceiveUpdate(String itemName, State newState) {

	}
}
