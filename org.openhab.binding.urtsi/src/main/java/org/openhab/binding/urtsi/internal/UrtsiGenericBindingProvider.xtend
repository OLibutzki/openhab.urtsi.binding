package org.openhab.binding.urtsi.internal

import java.util.Map
import java.util.regex.Pattern
import org.openhab.binding.urtsi.UrtsiBindingProvider
import org.openhab.core.items.Item
import org.openhab.core.library.items.RollershutterItem
import org.openhab.model.item.binding.AbstractGenericBindingProvider
import org.openhab.model.item.binding.BindingConfigParseException
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import static org.openhab.binding.urtsi.internal.UrtsiGenericBindingProvider.*

class UrtsiGenericBindingProvider extends AbstractGenericBindingProvider implements UrtsiBindingProvider {
	
	
	static val Logger logger = LoggerFactory::getLogger(typeof(UrtsiGenericBindingProvider))

	static val Pattern CONFIG_BINDING_PATTERN = Pattern::compile("(.*?):([0-9]*)")


	Map<String, UrtsiDevice> urtsiPorts = newHashMap

	override getBindingType() {
		"urtsi"
	}
	
	override validateItemType(Item item, String bindingConfig) throws BindingConfigParseException {
		switch item {
			RollershutterItem : {}
			default : 
				throw new BindingConfigParseException("item '" + item.name
					+ "' is of type '" + item.getClass().simpleName
					+ "', only RollershutterItems are allowed - please check your *.items configuration")
		}
	}
	
	override autoUpdate(String itemName) {
		if (itemName.providesBindingFor) {
			false
		} else {
			null
		}
	}
	
	override processBindingConfiguration(String context, Item item, String bindingConfig) throws BindingConfigParseException {
		super.processBindingConfiguration(context, item, bindingConfig)
		if (bindingConfig != null) {
			parseAndAddBindingConfig(item, bindingConfig)
		} else {
			logger.warn(getBindingType()+" bindingConfig is NULL (item=" + item
					+ ") -> processing bindingConfig aborted!")
		}
		
	}
	
	def protected void parseAndAddBindingConfig(Item item, String bindingConfig) throws BindingConfigParseException {
		val matcher = CONFIG_BINDING_PATTERN.matcher(bindingConfig)
		
		if (!matcher.matches) {
			throw new BindingConfigParseException("bindingConfig '" + bindingConfig + "' doesn't contain a valid Urtsii-binding-configuration. A valid configuration is matched by the RegExp '" + CONFIG_BINDING_PATTERN.pattern() + "'")
		}
		matcher.reset
		if (matcher.find) {
			val urtsiConfig = new UrtsiItemConfiguration(matcher.group(1), Integer::valueOf(matcher.group(2)))
			addBindingConfig(item, urtsiConfig)
			val port = urtsiConfig.port
			var urtsiDevice = urtsiPorts.get(port)
			if (urtsiDevice == null) {
				urtsiDevice = new UrtsiDevice(port)
				try {
					urtsiDevice.initialize
				} catch (InitializationException e) {
					throw new BindingConfigParseException(
							"Could not open serial port " + port + ": "
									+ e.message)
				} catch (Throwable e) {
					throw new BindingConfigParseException(
							"Could not open serial port " + port + ": "
									+ e.message)
				}
			}
			urtsiPorts.put(port, urtsiDevice)
		} else {
			throw new BindingConfigParseException("bindingConfig '" + bindingConfig + "' doesn't contain a valid Urtsii-binding-configuration. A valid configuration is matched by the RegExp '" + CONFIG_BINDING_PATTERN.pattern() + "'")
		}

	}
	

	override getDevice(String itemName) {
		val itemConfig = itemName.itemConfiguration
		val port = itemConfig?.port
		if (port != null) {
			urtsiPorts.get(port)
		}
	}
	

	override getChannel(String itemName) {
		itemName.itemConfiguration?.channel
	}
	
	def private getItemConfiguration(String itemName) {
		bindingConfigs.get(itemName) as UrtsiItemConfiguration
	}
	
}