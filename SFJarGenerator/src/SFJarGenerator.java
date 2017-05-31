import com.sforce.ws.tools.wsdlc;

public class SFJarGenerator {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		try {
			String[] args2 = {
					"E:/Projects/OneSaas-ECommerce/SFDownloader/jars/wsdl.partner.wsdl",
					"E:/Projects/OneSaas-ECommerce/SFDownloader/jars/wsc_partner.jar"};
			wsdlc.main(args2);
		} catch (Exception e) {
			
		}

	}

}
