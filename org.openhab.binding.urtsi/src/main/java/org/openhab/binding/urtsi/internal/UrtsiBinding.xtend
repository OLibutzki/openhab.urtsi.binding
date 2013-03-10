package org.openhab.binding.urtsi.internal

import java.util.Map
import java.util.Set
import java.util.regex.Pattern
import org.openhab.core.events.AbstractEventSubscriber
import org.openhab.model.item.binding.BindingConfigReader
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.openhab.core.items.Item
import org.openhab.model.item.binding.BindingConfigParseException
import org.openhab.core.library.items.RollershutterItem
import java.util.HashSet
import org.openhab.core.types.Command
import org.openhab.core.types.State
import org.openhab.core.types.Type
import org.openhab.core.library.types.UpDownType
import org.openhab.core.library.types.StopMoveType

import static org.openhab.core.library.types.UpDownType.*
import static org.openhab.core.library.types.StopMoveType.*
class UrtsiBinding extends AbstractEventSubscriber implements BindingConfigReader {

	static val Logger logger = LoggerFactory::getLogger(typeof(UrtsiBinding))
	
	Map<String, UrtsiDevice> urtsiPorts = newHashMap
	
	/** stores information about the which items are associated to which itemConfiguration. The map has this content structure: itemname -> UrtsiItemConfiguration */ 
	Map<String, UrtsiItemConfiguration> itemMap = newHashMap
	
	/** stores information about the context of items. The map has this content structure: context -> Set of itemNames */ 
	Map<String, Set<String>> contextMap = newHashMap

	static val Pattern CONFIG_BINDING_PATTERN = Pattern::compile("(.*?):([0-9]*)")
	
	static val String COMMAND_UP = "U"
	static val String COMMAND_DOWN = "D"
	static val String COMMAND_STOP = "S"	
	
	override getBindingType() {
		"urtsi"
	}


	override validateItemType(Item item, String bindingConfig)
			throws BindingConfigParseException {
		switch item {
			RollershutterItem : {}
			default : 
				throw new BindingConfigParseException("item '" + item.name
					+ "' is of type '" + item.getClass().simpleName
					+ "', only RollershutterItems are allowed - please check your *.items configuration")
		}
	}


	override processBindingConfiguration(String context, Item item,
			String bindingConfig) throws BindingConfigParseException {
		logger.debug("Process binding configuration for " + item.name + "; Context: " + context + "; Binding config: " + bindingConfig)
		val urtsiItemConfiguration = parseBindingConfig(bindingConfig)
		val port = urtsiItemConfiguration.getPort()
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
		itemMap.put(item.name, urtsiItemConfiguration);
		urtsiPorts.put(port, urtsiDevice);

		var itemNames = contextMap.get(context);
		if (itemNames == null) {
			itemNames = new HashSet<String>();
			contextMap.put(context, itemNames);
		}
		itemNames += item.name
	}
	
	def protected UrtsiItemConfiguration parseBindingConfig(String bindingConfig) throws BindingConfigParseException {
		val matcher = CONFIG_BINDING_PATTERN.matcher(bindingConfig)
		
		if (!matcher.matches) {
			throw new BindingConfigParseException("bindingConfig '" + bindingConfig + "' doesn't contain a valid Urtsii-binding-configuration. A valid configuration is matched by the RegExp '" + CONFIG_BINDING_PATTERN.pattern() + "'")
		}
		matcher.reset
		if (matcher.find) {
			return new UrtsiItemConfiguration(matcher.group(1), Integer::valueOf(matcher.group(2)));
		}
		throw new BindingConfigParseException("bindingConfig '" + bindingConfig + "' doesn't contain a valid Urtsii-binding-configuration. A valid configuration is matched by the RegExp '" + CONFIG_BINDING_PATTERN.pattern() + "'")

	}
	

	override receiveCommand(String itemName, Command command) {
		logger.debug("Received command for " + itemName + "! Command: " + command)
		sendToUrtsi(itemName, command)
	}
	
	override receiveUpdate(String itemName, State newState) {
		logger.debug("Received update for " + itemName + "! New state: " + newState)
		sendToUrtsi(itemName, newState)
	}

	def private void sendToUrtsi(String itemName, Type type) {
		if(itemMap.keySet().contains(itemName)) {
			logger.debug("Send to URTSI for item: " + itemName + "; Type: " + type)
			val  urtsiItemConfiguration = itemMap.get(itemName)
			val urtsiDevice = urtsiPorts.get(urtsiItemConfiguration.port)
			val actionKey= 
				switch type {
					UpDownType case UP : COMMAND_UP
					UpDownType case DOWN : COMMAND_DOWN
					StopMoveType case STOP : COMMAND_STOP
				}
			logger.debug("Action key: " + actionKey)
			if (actionKey != null) {
				val channel = String::format("%02d", urtsiItemConfiguration.channel)
				urtsiDevice.writeString("01" + channel + actionKey)
			}
		}
	}
	
	override removeConfigurations(String context) {
		val itemNames = contextMap.get(context)
		if (itemNames != null) {
			for (itemName : itemNames.filter[itemMap.containsKey(it)]) {
				// we remove all information in the urtsii devices
				val urtsiItemConfiguration = itemMap.get(itemName)
				val port = urtsiItemConfiguration.port
				val urtsiDevice = urtsiPorts.get(port);
				itemMap.remove(itemName);
				if (urtsiDevice != null) {
					var itemFound = false
					val iterator = itemMap.values().iterator()
					while (!itemFound && iterator.hasNext) {
						itemFound = iterator.next().port == port
					}
					// if there is no binding left, dispose this device
					if (!itemFound) {
						urtsiDevice.close;
						urtsiPorts.remove(port);
					}
				}

			}
			contextMap.remove(context);
		}
	}
}