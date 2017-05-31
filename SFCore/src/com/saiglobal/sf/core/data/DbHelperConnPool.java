package com.saiglobal.sf.core.data;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;

import com.saiglobal.sf.core.utility.GlobalProperties;
import com.saiglobal.sf.core.utility.Utility;

public class DbHelperConnPool extends DbHelper {

	private InitialContext cxt = null;
	private DataSource ds = null;
	private HashMap<Long, Connection> conns = new HashMap<Long, Connection>();
	
	public DbHelperConnPool(String jdbcName) {
		this.cmd = new GlobalProperties();
		this.cmd.setJdbcName(jdbcName);
		initDataSource();
	}

	public DbHelperConnPool(GlobalProperties cmd, String jdbcName) {
		this.cmd = cmd;
		this.cmd.setJdbcName(jdbcName);
		initDataSource();
	}

	public DbHelperConnPool(GlobalProperties cmd) {
		this.cmd = cmd;
		initDataSource();
	}

	@Override
	public boolean testConnection() {
		return true;
	}

	private void initDataSource() {
		try {
			cxt = new InitialContext();

			ds = (DataSource) cxt.lookup("java:/comp/env/" + cmd.getJdbcName());

			if (ds == null) {
				throw new NamingException("Data source not found!");
			}
		} catch (NamingException ne) {
			Utility.handleError(cmd, ne);
		}
	}
	
	@Override
	public Connection getConnection() throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		if (ds == null)
			throw new SQLException("Data source not found!");
		
		if (conns.containsKey(Thread.currentThread().getId())) {
			conns.get(Thread.currentThread().getId()).close();
			logger.debug("Closed connection for thread id: " + Thread.currentThread().getId());
		}
		
		Connection localConn = ds.getConnection();
		conns.put(Thread.currentThread().getId(), localConn);
		logger.debug("Opened connection for thread id: " + Thread.currentThread().getId());
		
		return localConn;
	}
	
	public Connection getNewConnection() throws InstantiationException, IllegalAccessException, ClassNotFoundException, SQLException {
		if (ds == null)
			throw new SQLException("Data source not found!");

		return ds.getConnection();
	}
	
	public void openConnection() throws InstantiationException,
			IllegalAccessException, ClassNotFoundException, SQLException {
		if (ds == null)
			throw new SQLException("Data source not found!");

		conn = ds.getConnection();
	}

	@Override
	public String executeScalar(String query) throws InstantiationException,
			IllegalAccessException, ClassNotFoundException, SQLException {

		logger.debug(query);
		Connection conni = ds.getConnection();
		Statement sti = null;
		ResultSet rsi = null;
		try {
			sti = conni.createStatement();
			sti.setMaxRows(1);
			rsi = sti.executeQuery(query);
			if (rsi.next()) {
				String retValue = rsi.getString(1);
				;
				return retValue;
			}
		} catch (SQLException sqlEx) {
			LogError(null, Utility.addSlashes(query));
			throw sqlEx;
		} finally {
			if (rsi != null) {
				try {
					rsi.close();
				} catch (SQLException ignore) {
				}
			}
			if (sti != null) {
				try {
					sti.close();
				} catch (SQLException ignore) {
				}
			}
			if (conni != null) {
				try {
					conni.close();
				} catch (Exception ignore) { /* ignore close errors */
				}
			}
			logger.debug("DB Connection closed successfully");
		}
		return null;
	}

	public int executeScalarInt(String query) throws InstantiationException,
			IllegalAccessException, ClassNotFoundException, SQLException {

		logger.debug(query);
		Connection conni = ds.getConnection();
		Statement sti = null;
		ResultSet rsi = null;
		try {
			sti = conni.createStatement();
			sti.setMaxRows(1);
			rsi = sti.executeQuery(query);
			if (rsi.next()) {
				int retValue = rsi.getInt(1);
				return retValue;
			}
		} catch (SQLException sqlEx) {
			LogError(null, Utility.addSlashes(query));
			throw sqlEx;
		} finally {
			if (rsi != null) {
				try {
					rsi.close();
				} catch (SQLException ignore) {
				}
			}
			if (sti != null) {
				try {
					sti.close();
				} catch (SQLException ignore) {
				}
			}
			if (conni != null) {
				try {
					conni.close();
				} catch (Exception ignore) { /* ignore close errors */
				}
			}
			logger.debug("DB Connection closed successfully");
		}
		return -1;
	}

	@Override
	public int executeStatement(String query) throws SQLException,
			ClassNotFoundException, IllegalAccessException,
			InstantiationException {

		// Removing non-ASCII
		//query = nonASCII.matcher(query).replaceAll("");
		logger.debug(query);
		Connection conni = ds.getConnection();
		Statement sti = null;

		try {
			sti = conni.createStatement();
			int count;
			count = sti.executeUpdate(query);
			return count;
		} catch (SQLException sqlEx) {
			LogError(null, Utility.addSlashes(query));
			throw sqlEx;
		} finally {
			if (sti != null) {
				try {
					sti.close();
				} catch (SQLException ignore) {
				}
			}
			if (conni != null) {
				try {
					conni.close();
				} catch (Exception ignore) { /* ignore close errors */
				}
			}
			logger.debug("DB Connection closed successfully");
		}
	}

	@Override
	public ResultSet executeSelect(String query, int maxRows)
			throws SQLException, ClassNotFoundException,
			IllegalAccessException, InstantiationException {
		Utility.startTimeCounter("executeSelect");

		Connection conni = this.getConnection();
		Statement sti = null;
		ResultSet rsi = null;
		logger.debug(query);
		try {
			sti = conni.createStatement();
			if (maxRows > 0) {
				sti.setMaxRows(maxRows);
			}
			Utility.startTimeCounter("executeSelect.query");
			rsi = sti.executeQuery(query);
			Utility.stopTimeCounter("executeSelect.query");
			Utility.stopTimeCounter("executeSelect");
			// CachedRowSet result = new FixedCachedRowSetImpl();
			// CachedRowSet result =
			// RowSetProvider.newFactory().createCachedRowSet();
			// result.populate(rsi);
			return rsi;
		} catch (SQLException sqlEx) {
			LogError(null, Utility.addSlashes(query));
			throw sqlEx;
		} finally {
			/*
			 * if (rsi != null) { try { rsi.close(); } catch (SQLException
			 * ignore) { } } if (sti != null) { try { sti.close(); } catch
			 * (SQLException ignore) { } } if (conni != null) { try {
			 * conni.close(); } catch (Exception ignore) { // ignore close
			 * errors } } logger.debug("DB Connection closed successfully");
			 */
		}
	}

	public void closeConnection() {
		if (conns.containsKey(Thread.currentThread().getId())) {
			try {
				conns.get(Thread.currentThread().getId()).close();
				logger.debug("Closed connection for thread id: " + Thread.currentThread().getId());
			} catch (SQLException e) {
			}
		}
	}
}
