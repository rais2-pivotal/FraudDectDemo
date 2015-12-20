package io.pivotal.demo.sko;


import io.pivotal.demo.sko.entity.PoSDevice;
import io.pivotal.demo.sko.entity.Transaction;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.PrimitiveIterator.OfLong;
import java.util.Random;
import java.util.UUID;
import java.util.logging.Logger;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@ComponentScan
@Configuration
public class Emulator implements CommandLineRunner {

	    @Value("${geodeUrl}")
		private String geodeURL;
		
	    @Value("${delayInMs}")
		private long delay;
	    
	    @Value("${setupMode}")
	    private boolean setupMode;

	    @Value("${numberOfAccounts}")
	    private int numberOfAccounts;
		
	    @Value("${numberOfTransactions}")
	    private int numberOfTransactions;
	    
	    private ArrayList<String> counties;
	   
	    private RestTemplate restTemplate = new RestTemplate();
		
		Logger logger = Logger.getLogger(Emulator.class.getName());

		@Override
		public void run(String... args) throws Exception {
			
			loadPoSCounties();
			
			if (setupMode){
				runSetup();
			}
			
			logger.info(">>>>> RUNNING SIMULATION");		
			logger.info("--------------------------------------");
			logger.info(">>> Geode rest endpoint: "+geodeURL);
			logger.info("--------------------------------------");
			
			logger.info(">>> Posting "+numberOfTransactions+" transactions ...");

			int numberOfDevices = counties.size();
			
			OfLong deviceIDs = new Random().longs(0, numberOfDevices).iterator();
			OfLong accountIDs = new Random().longs(0, numberOfAccounts).iterator();
			
			Random random = new Random();
			long mean = 100; // mean value for transactions
			long variance = 40; // variance

			if (numberOfTransactions<0) numberOfTransactions = Integer.MAX_VALUE;
			for (int i=0; i<numberOfTransactions; i++){
				//Map<String,Object> map = (Map)objects.get(i);
				Transaction t = new Transaction();
				t.setId(Math.abs(UUID.randomUUID().getLeastSignificantBits()));
				t.setDeviceId(deviceIDs.next());
				t.setAccountId(accountIDs.next());		
				t.setTimestamp(System.currentTimeMillis());
				t.setValue(Math.abs(mean+random.nextGaussian()*variance));
				Thread.sleep(delay);
				Transaction response = restTemplate.postForObject(geodeURL+RegionName.Transaction, t, Transaction.class);

			}

			logger.info("done");
			
			
		}

		/*
		 * Load the counties data from file
		 */
		private void loadPoSCounties() throws IOException {
			counties = new ArrayList<String>();
			
			InputStream is = ClassLoader.getSystemResourceAsStream("counties.csv");
			BufferedReader br = new BufferedReader(new InputStreamReader(is));
			
			String line = br.readLine();  //skip header
			while ( (line=br.readLine())!=null){
				String county = line.split("\"")[1];
				counties.add(county);
			}
		}

		private void runSetup() {

			int numberOfDevices = counties.size();
			
			logger.info(">>>>> RUNNING SETUP");		
			logger.info("--------------------------------------");
			logger.info(">>> Geode rest endpoint: "+geodeURL);
			logger.info("--------------------------------------");
			
			logger.info(">>> Adding "+numberOfDevices+" devices ...");

			// Add PoS'es
			for (int i=0; i<numberOfDevices; i++){
				PoSDevice device = new PoSDevice();
				device.setId(i+1);
				device.setLocation(counties.get(i));
				device.setMerchantName("Merchant "+i);
				PoSDevice response = restTemplate.postForObject(geodeURL+RegionName.PoS, device, PoSDevice.class);
			}
			


			
		}
}
