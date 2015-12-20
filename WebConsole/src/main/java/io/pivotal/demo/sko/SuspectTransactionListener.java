package io.pivotal.demo.sko;
import io.pivotal.demo.sko.util.GeodeClient;
import io.pivotal.demo.sko.util.TransactionsMap;

import java.util.Properties;

import com.gemstone.gemfire.cache.Declarable;
import com.gemstone.gemfire.cache.EntryEvent;
import com.gemstone.gemfire.cache.util.CacheListenerAdapter;
import com.gemstone.gemfire.pdx.PdxInstance;


public class SuspectTransactionListener extends CacheListenerAdapter
		implements Declarable {

	@Override
	public void init(Properties arg0) {
	}

	@Override
	public void afterCreate(EntryEvent event) {
		suspectTransactionFound(event);
	}

	@Override
	public void afterUpdate(EntryEvent event) {
		//do nothing. Only show new alerts.
	}

	
	public void suspectTransactionFound(EntryEvent e){
	
		Object obj = e.getNewValue();

		long transactionId;
		long deviceId;
		double value;
		long timestamp;
		boolean fraud;
		
		if (obj instanceof PdxInstance){			
			transactionId = ((Number)((PdxInstance)obj).getField("transactionId")).longValue();
			
			try{
				PdxInstance transaction = GeodeClient.getInstance().getTransaction(transactionId);
				deviceId = ((Number)transaction.getField("deviceId")).longValue();
				value = ((Number)transaction.getField("value")).doubleValue();			
				timestamp = ((Number)transaction.getField("timestamp")).longValue();
				fraud = true;			
				String location = GeodeClient.getInstance().getPoSLocation(deviceId);
				
				TransactionsMap.suspeciousTransactions.addTransaction(transactionId, value, location, fraud, timestamp);
			}
			catch(IllegalArgumentException ie){
				// transaction id couldn't be found in Gem
				ie.printStackTrace();
				// ignore.
			}
			
			
		}
		else throw new RuntimeException("new object is not PDX Instance.. it came as "+obj.getClass());

		
	}
	
	

}
