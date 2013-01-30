package org.openhab.binding.urtsi.internal;

public class UrtsiItemConfiguration {


	private String port;
	private int channel;
	
	public UrtsiItemConfiguration(String port, int channel) {
		super();
		this.port = port;
		this.channel = channel;
	}
	
	public String getPort() {
		return port;
	}
	public void setPort(String port) {
		this.port = port;
	}
	public int getChannel() {
		return channel;
	}
	public void setChannel(int channel) {
		this.channel = channel;
	}
}
