package org.openhab.binding.urtsi.internal

import org.openhab.core.items.GenericItem
import org.openhab.core.items.ItemRegistry
import org.openhab.core.library.types.StopMoveType
import org.openhab.core.library.types.UpDownType
import org.openhab.core.types.Command
import org.openhab.core.types.State
import org.openhab.core.types.Type
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import static org.openhab.binding.urtsi.internal.UrtsiBinding.*
import static org.openhab.core.library.types.StopMoveType.*
import static org.openhab.core.library.types.UpDownType.*

class UrtsiBinding extends AbstractUrtsiBinding {

	static val Logger logger = LoggerFactory::getLogger(typeof(UrtsiBinding))
	
	static val String COMMAND_UP = "U"
	static val String COMMAND_DOWN = "D"
	static val String COMMAND_STOP = "S"	
	
	ItemRegistry itemRegistry

	override protected void internalReceiveCommand(String itemName, Command command) {
		logger.debug("Received command for " + itemName + "! Command: " + command)
		val executedSuccessfully = sendToUrtsi(itemName, command)
		switch command {
			State case executedSuccessfully : {
				val item = itemRegistry.getItem(itemName)
				switch item {
					GenericItem : item.state = command
				}
			} 
		}
	}
	
	override protected void internalReceiveUpdate(String itemName, State newState) {
		logger.debug("Received update for " + itemName + "! New state: " + newState)
		sendToUrtsi(itemName, newState)
	}

	def private boolean sendToUrtsi(String itemName, Type type) {
		val provider = this.providers.head
		if (provider == null) {
			logger.trace("doesn't find matching binding provider [itemName={}, type={}]", itemName, type)
			return false
		}
		val urtsiDevice = provider.getDevice(itemName)
		val channel = provider.getChannel(itemName)
		
		if (urtsiDevice != null && channel != null) {
			logger.debug("Send to URTSI for item: " + itemName + "; Type: " + type)
			val actionKey= 
				switch type {
					UpDownType case UP : COMMAND_UP
					UpDownType case DOWN : COMMAND_DOWN
					StopMoveType case STOP : COMMAND_STOP
				}
			logger.debug("Action key: " + actionKey)
			if (actionKey != null) {
				val channelString = String::format("%02d", channel)
				val command = "01" + channelString + actionKey
				val executedSuccessfully = urtsiDevice.writeString(command)
				if (!executedSuccessfully) {
					logger.error("Command has not been processed [itemName={}, command={}]", itemName, command)
				}
				return executedSuccessfully
			}
		}
		false
	}

	def void setItemRegistry(ItemRegistry itemRegistry) {
		this.itemRegistry = itemRegistry
	}
	
	def void unsetItemRegistry(ItemRegistry itemRegistry) {
		this.itemRegistry = null
	}
	
}