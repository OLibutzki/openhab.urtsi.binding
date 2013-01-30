package org.openhab.binding.urtsi.internal;

import gnu.io.CommPortIdentifier;
import gnu.io.PortInUseException;
import gnu.io.SerialPort;
import gnu.io.UnsupportedCommOperationException;

import java.io.IOException;
import java.io.OutputStream;
import java.util.Enumeration;

import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class UrtsiDevice {

	private static final Logger logger = LoggerFactory.getLogger(UrtsiDevice.class);
	
	
	private static final int baud = 9600;
	private static final int databits = SerialPort.DATABITS_8;
	private static final int stopbit = SerialPort.STOPBITS_1;
	private static final int parity = SerialPort.PARITY_NONE;
	
	// Serial communication fields
	private String port;
	private CommPortIdentifier portId;
	private SerialPort serialPort;
	private OutputStream outputStream;
	

	public UrtsiDevice(String port) {
		this.port = port;
	}
	
	/**
	 * Initialize this device and open the serial port
	 * 
	 * @throws InitializationException  if port can not be opened
	 */
	public void initialize() throws InitializationException {		
		// parse ports and if the default port is found, initialized the reader
		Enumeration<?> portList = CommPortIdentifier.getPortIdentifiers();
		while (portList.hasMoreElements()) {
			CommPortIdentifier id = (CommPortIdentifier) portList.nextElement();
			if (id.getPortType() == CommPortIdentifier.PORT_SERIAL) {
				if (id.getName().equals(port)) {
					logger.debug("Serial port '{}' has been found.", port);
					portId = id;
				}
			}
		}
		if (portId != null) {
			// initialize serial port
			try {
				serialPort = (SerialPort) portId.open("openHAB", 2000);
			} catch (PortInUseException e) {
				throw new InitializationException(e);
			}


			try {
				// set port parameters
				serialPort.setSerialPortParams(baud, databits, stopbit,	parity);
			} catch (UnsupportedCommOperationException e) {
				throw new InitializationException(e);
			}

			try {
				// get the output stream
				outputStream = serialPort.getOutputStream();
			} catch (IOException e) {
				throw new InitializationException(e);
			}
		} else {
			StringBuilder sb = new StringBuilder();
			portList = CommPortIdentifier.getPortIdentifiers();
			while (portList.hasMoreElements()) {
				CommPortIdentifier id = (CommPortIdentifier) portList.nextElement();
				if (id.getPortType() == CommPortIdentifier.PORT_SERIAL) {
					sb.append(id.getName() + "\n");
				}
			}
			throw new InitializationException("Serial port '" + port + "' could not be found. Available ports are:\n" + sb.toString());
		}
	}
	
	/**
	 * Sends a string to the serial port of this device
	 * 
	 * @param msg the string to send
	 */
	public void writeString(String msg) {
		logger.debug("Writing '{}' to serial port {}", new String[] { msg, port });
		try {
			// write string to serial port
			outputStream.write(msg.getBytes());
			outputStream.flush();
		} catch (IOException e) {
			logger.error("Error writing '{}' to serial port {}: {}", new String[] { msg, port, e.getMessage() });
		}
	}
	
	/**
	 * Close this serial device
	 */
	public void close() {
		serialPort.removeEventListener();
		IOUtils.closeQuietly(outputStream);
		serialPort.close();
	}

	
}
