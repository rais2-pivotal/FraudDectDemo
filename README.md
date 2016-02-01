# wwko2016-demo

Steps to run the demo

1. Create the GPDB model on file Server/scripts/model.sql

If you already have GPDB setup, truncate the tables SUSPECT and TRANSACTION


2. Start the GemFire cluster

$ cd Server
$ ./startup.sh

3. Start the Web Console

$ cd WebConsole
$ ./gradlew bootRun


4. Start the Emulator

$ cd PoS_Emulator
$ ./gradlew bootRun


