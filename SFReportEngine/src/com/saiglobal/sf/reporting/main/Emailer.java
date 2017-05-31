package com.saiglobal.sf.reporting.main;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.net.InetAddress;
import java.sql.ResultSet;

import org.apache.log4j.Logger;

import com.saiglobal.sf.core.data.DbHelperDataSource;
import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class Emailer {

	private static final int emailDelay = 10000;
	private static final Logger logger = Logger.getLogger(Emailer.class);
	
	public static void main(String[] args) throws InterruptedException {
		logger.info("Starting Emailer");
		boolean gotLock = true;
		String lockName = "emailer.lck";
		
		try {
			gotLock = Utility.getLock(lockName);
			if (!gotLock) {
				logger.info("Cannot get lock.  Process already running.  Exiting");
				return;
			}
		
			GlobalProperties gp = Utility.getProperties();
			DbHelperDataSource db = new DbHelperDataSource(gp, "analytics");
			
			ResultSet rs = db.executeSelectThreadSafe("select * from email_queue where (createdBy = '" + InetAddress.getLocalHost().getHostName() + "' and is_sent=0) or (attachments is null and is_sent=0)", -1);
			while (rs.next()) {
				try {
					System.out.println(rs.getString("attachments"));
					Utility.sendEmail(gp, rs.getString("to"), rs.getString("subject"), rs.getString("body"), (rs.getString("attachments")==null)?new String[0]:rs.getString("attachments").split(","));
					db.executeStatement("update email_queue set is_sent=1, last_send_try=utc_timestamp(), tries=" + (rs.getInt("tries")+1) + ", `from`='" + gp.getMail_smtp_user() + "' where id=" + rs.getString("id"));
				} catch (Exception e) {
					ByteArrayOutputStream baos = new ByteArrayOutputStream();
					PrintStream ps = new PrintStream(baos);
					e.printStackTrace(ps);
					db.executeStatement("update email_queue set is_sent=0, last_send_try=utc_timestamp(), last_send_error='" + baos.toString() + "', tries=" + (rs.getInt("tries")+1) + ", `from`='" + gp.getMail_smtp_user() + "' where id=" + rs.getString("id"));
				}
				Thread.sleep(emailDelay);
			}
		} catch (Exception e) {
			Utility.handleError(Utility.getProperties(), e);
		} finally {
			if (gotLock)
				Utility.releaseLock(lockName);
			logger.info("Finished Emailer");
		}
	}
}
