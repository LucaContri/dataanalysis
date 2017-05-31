package com.saiglobal.sf.core.data;

import java.io.InputStream;
import java.io.Reader;
import java.math.BigDecimal;
import java.net.URL;
import java.sql.Array;
import java.sql.Blob;
import java.sql.Clob;
import java.sql.Date;
import java.sql.NClob;
import java.sql.Ref;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.RowId;
import java.sql.SQLException;
import java.sql.SQLWarning;
import java.sql.SQLXML;
import java.sql.Statement;
import java.sql.Time;
import java.sql.Timestamp;
import java.sql.Types;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.saiglobal.sf.core.utility.Utility;
import com.sforce.soap.partner.PartnerConnection;
import com.sforce.soap.partner.QueryResult;
import com.sforce.soap.partner.sobject.SObject;
import com.sforce.ws.ConnectionException;
import com.sforce.ws.bind.XmlObject;

public class SFResultSet implements ResultSet {
	private PartnerConnection conn;
	private QueryResult qr;
	private SObject[] records = new SObject[0];
	private int pointer = -1;
	private ResultSetMetaData rsmd;
	
	public SFResultSet(PartnerConnection conn, String sql) throws ConnectionException {
		this.conn = conn;
		this.qr = conn.query(sql);
		if(qr.getRecords() != null)
			this.records = qr.getRecords();
		this.pointer = -1;
		initResultSetMetaData(qr, sql);
	}

	private void initResultSetMetaData(QueryResult qr, String sql) {
		Set<String> columnNamesList = getFieldNames(records[0],null);//getFieldsFromSql(sql);
		String[] columnNames = columnNamesList.toArray(new String[columnNamesList.size()]);
		int[] columnTypes = new int[columnNames.length];
		for (int i=0; i<columnNames.length; i++) {
			columnTypes[i] = getFieldType(columnNames[i]);
		}
		this.rsmd = new SFResultSetMetaData(columnNames, columnTypes);
	}
	
	private Object getFieldValue(SObject so, String fieldName) {
		String[] parts = fieldName.split("\\.", 2);
		if (parts.length>1) {
			return getFieldValue((SObject) so.getSObjectField(parts[0]), parts[1]);
		}
		return so.getField(parts[0]);
	}
	
	private int getFieldType(String field) {
		int type = Types.VARCHAR;
		SObject[] records = this.qr.getRecords();
		if ((records != null) && (records.length>0)) {
			Object o = records[0].getField(field);
			try {
				Double.parseDouble((String)o);
				type = Types.DECIMAL;
				return type;
			} catch (Exception e) {
				// Ignore.  Not a double.
			}
			
			try {
				SimpleDateFormat sfd = Utility.getSoqldateformat();
				sfd.parse((String) o);
				type = Types.DATE;
				return type;
			} catch (Exception e) {
				// Ignore.  Not a date.
			}
		}
		
		return type;
	}
	
	private Set<String> getFieldNames(XmlObject o, String prefix) {
		if (prefix!= null && prefix.equalsIgnoreCase("records"))
			prefix = null; 
		Set<String> retValue = new HashSet<String>();
		if (o != null) {
			if (o.hasChildren()) {
				Iterator<XmlObject> children = o.getChildren();
				while(children.hasNext()) {
					XmlObject child = children.next();
					retValue.addAll(getFieldNames(child, o.getName().getLocalPart()));
				}
			} else {
				retValue.add(((prefix==null)||(prefix.equalsIgnoreCase(""))?"":(prefix+".")) + o.getName().getLocalPart());
			}
		}
		return retValue;
	}
	
	@SuppressWarnings("unused")
	private List<String> getFieldsFromSql(String sql) {
		List<String> retValue = new ArrayList<String>();
		
		String[] fields = sql.replace("FROM", "from").replace("SELECT", "select").split("from")[0].replace("select", "").split(",");
		for (String s : fields) {
			retValue.add(s.trim());
		}
		return retValue;
	}
	
	@Override
	public boolean isWrapperFor(Class<?> arg0) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public <T> T unwrap(Class<T> arg0) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public boolean absolute(int row) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public void afterLast() throws SQLException {
		this.pointer = this.records.length;
	}

	@Override
	public void beforeFirst() throws SQLException {
		this.pointer = 0;
	}

	@Override
	public void cancelRowUpdates() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public void clearWarnings() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public void close() throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void deleteRow() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public int findColumn(String columnLabel) throws SQLException {
		for (int i = 0; i < this.getMetaData().getColumnCount(); i++) {
			if(this.getMetaData().getColumnName(i).equalsIgnoreCase(columnLabel))
				return i+1;
		}
		return 0;
	}

	@Override
	public boolean first() throws SQLException {
		return pointer==0;
	}

	@Override
	public Array getArray(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Array getArray(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public InputStream getAsciiStream(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public InputStream getAsciiStream(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public BigDecimal getBigDecimal(int i) throws SQLException {
		try {
			return new BigDecimal(Double.parseDouble(getFieldValue(records[pointer],getMetaData().getColumnLabel(i)).toString()));
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public BigDecimal getBigDecimal(String columnLabel) throws SQLException {
		try {
			return new BigDecimal(Double.parseDouble(getFieldValue(records[pointer], columnLabel).toString()));
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public BigDecimal getBigDecimal(int columnIndex, int scale)
			throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public BigDecimal getBigDecimal(String columnLabel, int scale)
			throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public InputStream getBinaryStream(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public InputStream getBinaryStream(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Blob getBlob(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Blob getBlob(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public boolean getBoolean(int i) throws SQLException {
		try {
			return Boolean.parseBoolean(getFieldValue(records[pointer],getMetaData().getColumnLabel(i)).toString());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public boolean getBoolean(String columnLabel) throws SQLException {
		try {
			return Boolean.parseBoolean(getFieldValue(records[pointer], columnLabel).toString());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public byte getByte(int i) throws SQLException {
		try {
			return Byte.parseByte(getFieldValue(records[pointer],getMetaData().getColumnLabel(i)).toString());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public byte getByte(String columnLabel) throws SQLException {
		try {
			return Byte.parseByte(getFieldValue(records[pointer], columnLabel).toString());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public byte[] getBytes(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public byte[] getBytes(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Reader getCharacterStream(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Reader getCharacterStream(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Clob getClob(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Clob getClob(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public int getConcurrency() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public String getCursorName() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Date getDate(int i) throws SQLException {
		try {
			String value = (String) getFieldValue(records[pointer], getMetaData().getColumnLabel(i));
			if (value == null || value.equalsIgnoreCase(""))
				return null;
			return new Date(Utility.getSoqldateformat().parse(value).getTime());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public Date getDate(String columnLabel) throws SQLException {
		try {
			String value = (String) getFieldValue(records[pointer], columnLabel);
			if (value == null || value.equalsIgnoreCase(""))
				return null;
			return new Date(Utility.getSoqldateformat().parse(value).getTime());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public Date getDate(int columnIndex, Calendar cal) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Date getDate(String columnLabel, Calendar cal) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public double getDouble(int i) throws SQLException {
		try {
			String value = (String) getFieldValue(records[pointer], getMetaData().getColumnLabel(i));
			if (value == null || value.equalsIgnoreCase(""))
				return 0;
			return Double.parseDouble(value);
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public double getDouble(String columnLabel) throws SQLException {
		try {
			String value = (String) getFieldValue(records[pointer], columnLabel);
			if (value == null || value.equalsIgnoreCase(""))
				return 0;
			return Double.parseDouble(value);
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public int getFetchDirection() throws SQLException {
		return ResultSet.FETCH_FORWARD;
	}

	@Override
	public int getFetchSize() throws SQLException {
		return 0;
	}

	@Override
	public float getFloat(int i) throws SQLException {
		try {
			String value = (String) getFieldValue(records[pointer], getMetaData().getColumnLabel(i));
			if (value == null || value.equalsIgnoreCase(""))
				return 0;
			return Float.parseFloat(value);
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public float getFloat(String columnLabel) throws SQLException {
		try {
			String value = (String) getFieldValue(records[pointer], columnLabel);
			if (value == null || value.equalsIgnoreCase(""))
				return 0;
			return Float.parseFloat(value);
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public int getHoldability() throws SQLException {
		return 0;
	}

	@Override
	public int getInt(int i) throws SQLException {
		try {
			return Integer.parseInt(getFieldValue(records[pointer],getMetaData().getColumnLabel(i)).toString());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public int getInt(String columnLabel) throws SQLException {
		try {
			return Integer.parseInt(getFieldValue(records[pointer], columnLabel).toString());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public long getLong(int i) throws SQLException {
		try {
			return Long.parseLong(getFieldValue(records[pointer],getMetaData().getColumnLabel(i)).toString());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public long getLong(String columnLabel) throws SQLException {
		try {
			return Long.parseLong(getFieldValue(records[pointer], columnLabel).toString());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public ResultSetMetaData getMetaData() throws SQLException {
		return rsmd;
	}

	@Override
	public Reader getNCharacterStream(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Reader getNCharacterStream(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public NClob getNClob(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public NClob getNClob(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public String getNString(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public String getNString(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Object getObject(int i) throws SQLException {
		try {
			if (this.getMetaData().getColumnType(i) == Types.DATE)
				return getDate(i);
			if (this.getMetaData().getColumnType(i) == Types.DECIMAL)
				return getDouble(i);
			return getString(i);
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public Object getObject(String columnLabel) throws SQLException {
		try {
			return getFieldValue(records[pointer], columnLabel);
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public Object getObject(int columnIndex, Map<String, Class<?>> map) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Object getObject(String columnLabel, Map<String, Class<?>> map)
			throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public <T> T getObject(int columnIndex, Class<T> type) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public <T> T getObject(String columnLabel, Class<T> type)
			throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Ref getRef(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Ref getRef(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public int getRow() throws SQLException {
		return pointer+1;
	}

	@Override
	public RowId getRowId(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public RowId getRowId(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public SQLXML getSQLXML(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public SQLXML getSQLXML(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public short getShort(int i) throws SQLException {
		try {
			return Short.parseShort(getFieldValue(records[pointer],getMetaData().getColumnLabel(i)).toString());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public short getShort(String columnLabel) throws SQLException {
		try {
			return Short.parseShort(getFieldValue(records[pointer], columnLabel).toString());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public Statement getStatement() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public String getString(int i) throws SQLException {
		try {
			return (String) getFieldValue(records[pointer], getMetaData().getColumnName(i));
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public String getString(String columnLabel) throws SQLException {
		try {
			return (String) getFieldValue(records[pointer], columnLabel);
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public Time getTime(int i) throws SQLException {
		try {
			return new Time(Utility.getSoqldateformat().parse(getFieldValue(records[pointer],getMetaData().getColumnLabel(i)).toString()).getTime());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public Time getTime(String columnLabel) throws SQLException {
		try {
			return new Time(Utility.getSoqldateformat().parse(getFieldValue(records[pointer], columnLabel).toString()).getTime());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public Time getTime(int columnIndex, Calendar cal) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Time getTime(String columnLabel, Calendar cal) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Timestamp getTimestamp(int i) throws SQLException {
		try {
			return new Timestamp(Utility.getSoqldateformat().parse(getFieldValue(records[pointer],getMetaData().getColumnLabel(i)).toString()).getTime());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public Timestamp getTimestamp(String columnLabel) throws SQLException {
		try {
			return new Timestamp(Utility.getSoqldateformat().parse(getFieldValue(records[pointer], columnLabel).toString()).getTime());
		} catch (Exception e) {
			throw new SQLException(e.getCause());
		}
	}

	@Override
	public Timestamp getTimestamp(int columnIndex, Calendar cal)
			throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public Timestamp getTimestamp(String columnLabel, Calendar cal)
			throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public int getType() throws SQLException {
		return ResultSet.TYPE_FORWARD_ONLY;
	}

	@Override
	public URL getURL(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public URL getURL(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public InputStream getUnicodeStream(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public InputStream getUnicodeStream(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public SQLWarning getWarnings() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public void insertRow() throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public boolean isAfterLast() throws SQLException {
		return pointer>=this.records.length;
	}

	@Override
	public boolean isBeforeFirst() throws SQLException {
		return pointer<0;
	}

	@Override
	public boolean isClosed() throws SQLException {
		return false;
	}

	@Override
	public boolean isFirst() throws SQLException {
		return pointer==0;
	}

	@Override
	public boolean isLast() throws SQLException {
		return pointer==(this.records.length-1);
	}

	@Override
	public boolean last() throws SQLException {
		pointer=(this.records.length-1);
		return pointer>=0;
	}

	@Override
	public void moveToCurrentRow() throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void moveToInsertRow() throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public boolean next() throws SQLException {
		pointer++;
		try {
			if(pointer>=records.length) {
				if(qr.isDone()) {
					return false;
				} else {
					qr = conn.queryMore(qr.getQueryLocator());
					if(qr.getRecords() != null)
						this.records = qr.getRecords();
					pointer = 0;
				}
			}
		} catch (ConnectionException ce) {
			throw new SQLException(ce);
		}
		return pointer>=0 && pointer<records.length;
	}

	@Override
	public boolean previous() throws SQLException {
		pointer--;
		return pointer>=0 && pointer<records.length;
	}

	@Override
	public void refreshRow() throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public boolean relative(int rows) throws SQLException {
		pointer+=rows;
		return pointer>=0 && pointer<records.length;
	}

	@Override
	public boolean rowDeleted() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public boolean rowInserted() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public boolean rowUpdated() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

	@Override
	public void setFetchDirection(int direction) throws SQLException {
		throw new SQLException("TYPE_FORWARD_ONLY");

	}

	@Override
	public void setFetchSize(int rows) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateArray(int columnIndex, Array x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateArray(String columnLabel, Array x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateAsciiStream(int columnIndex, InputStream x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateAsciiStream(String columnLabel, InputStream x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateAsciiStream(int columnIndex, InputStream x, int length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateAsciiStream(String columnLabel, InputStream x, int length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateAsciiStream(int columnIndex, InputStream x, long length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateAsciiStream(String columnLabel, InputStream x, long length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBigDecimal(int columnIndex, BigDecimal x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBigDecimal(String columnLabel, BigDecimal x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBinaryStream(int columnIndex, InputStream x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBinaryStream(String columnLabel, InputStream x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBinaryStream(int columnIndex, InputStream x, int length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBinaryStream(String columnLabel, InputStream x, int length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBinaryStream(int columnIndex, InputStream x, long length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBinaryStream(String columnLabel, InputStream x,
			long length) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBlob(int columnIndex, Blob x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBlob(String columnLabel, Blob x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBlob(int columnIndex, InputStream inputStream)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBlob(String columnLabel, InputStream inputStream)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBlob(int columnIndex, InputStream inputStream, long length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBlob(String columnLabel, InputStream inputStream,
			long length) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBoolean(int columnIndex, boolean x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBoolean(String columnLabel, boolean x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateByte(int columnIndex, byte x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateByte(String columnLabel, byte x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBytes(int columnIndex, byte[] x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateBytes(String columnLabel, byte[] x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateCharacterStream(int columnIndex, Reader x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateCharacterStream(String columnLabel, Reader reader)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateCharacterStream(int columnIndex, Reader x, int length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateCharacterStream(String columnLabel, Reader reader,
			int length) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateCharacterStream(int columnIndex, Reader x, long length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateCharacterStream(String columnLabel, Reader reader,
			long length) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateClob(int columnIndex, Clob x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateClob(String columnLabel, Clob x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateClob(int columnIndex, Reader reader) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateClob(String columnLabel, Reader reader)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateClob(int columnIndex, Reader reader, long length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateClob(String columnLabel, Reader reader, long length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateDate(int columnIndex, Date x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateDate(String columnLabel, Date x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateDouble(int columnIndex, double x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateDouble(String columnLabel, double x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateFloat(int columnIndex, float x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateFloat(String columnLabel, float x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateInt(int columnIndex, int x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateInt(String columnLabel, int x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateLong(int columnIndex, long x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateLong(String columnLabel, long x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNCharacterStream(int columnIndex, Reader x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNCharacterStream(String columnLabel, Reader reader)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNCharacterStream(int columnIndex, Reader x, long length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNCharacterStream(String columnLabel, Reader reader,
			long length) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNClob(int columnIndex, NClob nClob) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNClob(String columnLabel, NClob nClob)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNClob(int columnIndex, Reader reader) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNClob(String columnLabel, Reader reader)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNClob(int columnIndex, Reader reader, long length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNClob(String columnLabel, Reader reader, long length)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNString(int columnIndex, String nString)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNString(String columnLabel, String nString)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNull(int columnIndex) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateNull(String columnLabel) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateObject(int columnIndex, Object x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateObject(String columnLabel, Object x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateObject(int columnIndex, Object x, int scaleOrLength)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateObject(String columnLabel, Object x, int scaleOrLength)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateRef(int columnIndex, Ref x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateRef(String columnLabel, Ref x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateRow() throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateRowId(int columnIndex, RowId x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateRowId(String columnLabel, RowId x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateSQLXML(int columnIndex, SQLXML xmlObject)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateSQLXML(String columnLabel, SQLXML xmlObject)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateShort(int columnIndex, short x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateShort(String columnLabel, short x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateString(int columnIndex, String x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateString(String columnLabel, String x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateTime(int columnIndex, Time x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateTime(String columnLabel, Time x) throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateTimestamp(int columnIndex, Timestamp x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public void updateTimestamp(String columnLabel, Timestamp x)
			throws SQLException {
		throw new SQLException("Unimplemented method");

	}

	@Override
	public boolean wasNull() throws SQLException {
		throw new SQLException("Unimplemented method");
	}

}
