package org.openhab.binding.urtsi;

import org.openhab.binding.urtsi.internal.UrtsiDevice;
import org.openhab.core.autoupdate.AutoUpdateBindingProvider;

public interface UrtsiBindingProvider extends AutoUpdateBindingProvider {

	UrtsiDevice getDevice(String itemName);
	
	int getChannel (String itemName);
}
