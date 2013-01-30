package org.openhab.binding.urtsi.internal;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.openhab.core.events.EventSubscriber;
import org.openhab.core.items.Item;
import org.openhab.core.library.items.RollershutterItem;
import org.openhab.core.library.types.StopMoveType;
import org.openhab.core.library.types.UpDownType;
import org.openhab.core.types.Command;
import org.openhab.core.types.State;
import org.openhab.core.types.Type;
import org.openhab.model.item.binding.BindingConfigParseException;
import org.openhab.model.item.binding.BindingConfigReader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class UrtsiBinding implements EventSubscriber, BindingConfigReader {

	
	@SuppressWarnings("unused")
	private static final Logger logger = LoggerFactory.getLogger(UrtsiBinding.class);
	
	private Map<String, UrtsiDevice> urtsiPorts = new HashMap<String, UrtsiDevice>();
	
	/** stores information about the which items are associated to which itemConfiguration. The map has this content structure: itemname -> UrtsiItemConfiguration */ 
	private Map<String, UrtsiItemConfiguration> itemMap = new HashMap<String, UrtsiItemConfiguration>();
	
	/** stores information about the context of items. The map has this content structure: context -> Set of itemNames */ 
	private Map<String, Set<String>> contextMap = new HashMap<String, Set<String>>();

	private static final Pattern CONFIG_BINDING_PATTERN = Pattern.compile("(.*?):([0-9]*)");
	
	@Override
	public String getBindingType() {
		return "urtsi";
	}


	@Override
	public void validateItemType(Item item, String bindingConfig)
			throws BindingConfigParseException {
		if (!(item instanceof RollershutterItem)) {
			throw new BindingConfigParseException("item '" + item.getName()
					+ "' is of type '" + item.getClass().getSimpleName()
					+ "', only RollershutterItems are allowed - please check your *.items configuration");
		}
	}


	@Override
	public void processBindingConfiguration(String context, Item item,
			String bindingConfig) throws BindingConfigParseException {
		UrtsiItemConfiguration urtsiItemConfiguration = parseBindingConfig(bindingConfig);
		String port = urtsiItemConfiguration.getPort();
		UrtsiDevice urtsiDevice = urtsiPorts.get(port);
		if (urtsiDevice == null) {
			urtsiDevice = new UrtsiDevice(port);
				try {
				urtsiDevice.initialize();
			} catch (InitializationException e) {
				throw new BindingConfigParseException(
						"Could not open serial port " + port + ": "
								+ e.getMessage());
			} catch (Throwable e) {
				throw new BindingConfigParseException(
						"Could not open serial port " + port + ": "
								+ e.getMessage());
			}
			itemMap.put(item.getName(), urtsiItemConfiguration);
			urtsiPorts.put(port, urtsiDevice);
		}

		Set<String> itemNames = contextMap.get(context);
		if (itemNames == null) {
			itemNames = new HashSet<String>();
			contextMap.put(context, itemNames);
		}
		itemNames.add(item.getName());
	}
	
	protected UrtsiItemConfiguration parseBindingConfig(String bindingConfig) throws BindingConfigParseException {
		Matcher matcher = CONFIG_BINDING_PATTERN.matcher(bindingConfig);
		
		if (!matcher.matches()) {
			throw new BindingConfigParseException("bindingConfig '" + bindingConfig + "' doesn't contain a valid Urtsii-binding-configuration. A valid configuration is matched by the RegExp '" + CONFIG_BINDING_PATTERN.pattern() + "'");
		}
		matcher.reset();
		if (matcher.find()) {
			return new UrtsiItemConfiguration(matcher.group(1), Integer.valueOf(matcher.group(2)));
		}
		throw new BindingConfigParseException("bindingConfig '" + bindingConfig + "' doesn't contain a valid Urtsii-binding-configuration. A valid configuration is matched by the RegExp '" + CONFIG_BINDING_PATTERN.pattern() + "'");

	}
	
	/**
	 * {@inheritDoc}
	 */
	public void receiveCommand(String itemName, Command command) {
		sendToUrtsi(itemName, command);
	}
	
	/**
	 * {@inheritDoc}
	 */
	public void receiveUpdate(String itemName, State newState) {
		sendToUrtsi(itemName, newState);
	}

	private void sendToUrtsi(String itemName, Type type) {
		if(itemMap.keySet().contains(itemName)) {
			UrtsiItemConfiguration urtsiItemConfiguration = itemMap.get(itemName);
			UrtsiDevice urtsiDevice = urtsiPorts.get(urtsiItemConfiguration.getPort());
			String actionKey = null;
			if (type instanceof UpDownType) {
				UpDownType upDownType = (UpDownType) type;
				switch (upDownType) {
					case UP :  actionKey = "U"; break;
					case DOWN :  actionKey = "D"; break;
				}
			} else if (type instanceof StopMoveType) {
				StopMoveType stopMoveType = (StopMoveType) type;
				switch (stopMoveType) {
					case STOP : actionKey = "U"; break;
					default: break;
				}
			}
			if (actionKey != null) {
				String channel = String.format("%02d", urtsiItemConfiguration.getChannel());
				urtsiDevice.writeString("01" + channel + actionKey);
			}
		}
	}
	
	/**
	 * {@inheritDoc}
	 */
	public void removeConfigurations(String context) {
		Set<String> itemNames = contextMap.get(context);
		if(itemNames!=null) {
			for(String itemName : itemNames) {
				// we remove all information in the urtsii devices
				UrtsiItemConfiguration urtsiItemConfiguration = itemMap.get(itemName);
				String port = urtsiItemConfiguration.getPort();
				UrtsiDevice urtsiDevice = urtsiPorts.get(port);
				itemMap.remove(itemName);
				if(urtsiDevice==null) {
					continue;
				}
				boolean itemFound = false;
				for (Iterator<UrtsiItemConfiguration> iterator = itemMap.values().iterator(); iterator
						.hasNext() && !itemFound;) {
					itemFound = iterator.next().getPort().equals(port);
				}
				// if there is no binding left, dispose this device
				if (!itemFound) {
					urtsiDevice.close();
					urtsiPorts.remove(port);
				}

			}
			contextMap.remove(context);
		}
	}
	

}
