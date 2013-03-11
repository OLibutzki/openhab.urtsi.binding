package org.openhab.binding.urtsi.internal

import org.openhab.core.binding.BindingConfig

@Data
class UrtsiItemConfiguration implements BindingConfig {
	
	String port
	int channel
}