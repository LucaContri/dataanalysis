package com.saiglobal.sf.allocator.processor;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.apache.log4j.Logger;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.apache.spark.ml.clustering.KMeans;
import org.apache.spark.ml.clustering.KMeansModel;
import org.apache.spark.ml.linalg.Vector;
import org.apache.spark.ml.linalg.VectorUDT;
import org.apache.spark.ml.linalg.Vectors;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.RowFactory;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.types.Metadata;
import org.apache.spark.sql.types.StructField;
import org.apache.spark.sql.types.StructType;

import com.google.code.geocoder.model.LatLng;
import com.google.ortools.linearsolver.MPConstraint;
import com.google.ortools.linearsolver.MPObjective;
import com.google.ortools.linearsolver.MPSolver;
import com.google.ortools.linearsolver.MPVariable;
import com.saiglobal.sf.allocator.data.DbHelper;
import com.saiglobal.sf.allocator.rules.ProcessorRule;
import com.saiglobal.sf.core.model.ScheduleParameters;
import com.saiglobal.sf.core.utility.Utility;

public class PizzaHutMIPProcessor implements Processor {
	static {
		// OR Tools
		// https://github.com/google/or-tools/releases/download/v5.1/or-tools_flatzinc_VisualStudio2015-64bit_v5.1.4045.zip
		// https://developers.google.com/optimization/
		System.loadLibrary("jniortools"); 
	}
	
	private static final StructType schema = new StructType(new StructField[]{
			  new StructField("features", new VectorUDT(), false, Metadata.empty()),
			});
	private static final SparkSession spark = SparkSession
			  .builder()
			  .appName("Java Spark K-Mean Store Clustering")
			  .master("local[2]")
			  .config("spark.executor.memory","4g")
			  .getOrCreate();;
	private DbHelper db;
	//private ScheduleParameters sp;
	private static String inputFileName = "C:\\Users\\conluc0\\Downloads\\PizzaHut.Stores.v2.xlsx";
	private List<Store> stores = null;
	private List<Set<Store>> quartersAllocation = null;
	private Map<String, Cluster> clusters = null;
	protected Logger logger = Logger.getLogger(PizzaHutMIPProcessor.class);
	private String solverType = "CBC_MIXED_INTEGER_PROGRAMMING";
	private double weekendAuditsMin = 0.25;
	private double eveningAuditsMin = 0.30;
	private double dailyWeekdayAuditsMin = 0.10;
	private double dailyWeekendAuditsMin = 0.05;
	private double quarterAuditsMin = 0.245;
	private int max_visits_auditor_quarter_dayLunch = 26;
	private int max_visits_auditor_quarter_dayEvening = 13;
	final long maxExecTime = 3000000; // 5 minutes
	
	@Override
	public List<ProcessorRule> getRules() {
		return new ArrayList<ProcessorRule>();
	}

	@Override
	public int getBatchSize() {
		return 0;
	}

	@Override
	public void execute() throws Exception {
		init();
		// Presolve allocates audits to quarters
		MPVariable[][][] x = solve(true);

		quartersAllocation = new ArrayList<Set<Store>>();
		quartersAllocation.add(new HashSet<Store>());
		quartersAllocation.add(new HashSet<Store>());
		quartersAllocation.add(new HashSet<Store>());
		quartersAllocation.add(new HashSet<Store>());
		// Store allocation to quarters
		for (int q = 0; q < x[0].length; q++) {
			for (int s = 0; s < x.length; s++) {
				for (int w = 0; w < x[0][0].length; w++) {
					if (x[s][q][w] != null && x[s][q][w].solutionValue()>0) {
						Store store = new Store();
						store.setLatitude(stores.get(s).getCoordinates().getLat().doubleValue());
						store.setLongitude(stores.get(s).getCoordinates().getLng().doubleValue());
						store.setAddress(stores.get(s).getAddress(), db);
						store.setAuditor(stores.get(s).getAuditor());
						store.setFrequency(stores.get(s).getFrequency());
						store.setName(stores.get(s).getName());
						store.setStoreNo(stores.get(s).getStoreNo());
						store.setQuarter(q);
						quartersAllocation.get(q).add(store);
					}
				}
			}
		}
		
		x = solve(false);
		
		// Output Solution
		saveOutput(x);	
	}
	
	private MPVariable[][][] solve(boolean presolve) throws Exception {
		// Instantiate a mixed-integer solver
		MPSolver solver = createSolver(solverType);
	    if (solver == null) {
	      logger.error("Could not create solver " + solverType);
	      throw new Exception("Could not create solver " + solverType);
	    }
	    
	    // Variables [store][quarter][weeklyslot]
		MPVariable[][][] x = new MPVariable[stores.size()][4][14];
		
		for (int s = 0; s < stores.size(); s++) {
			for (int q = 0; q < 4; q++) {
				for (int w = 0; w < 14; w++) {
					x[s][q][w] = solver.makeIntVar(0, 1, "x["+s+","+q+","+w+"]");
				}
			}
		}
		
		// Constraints
		// All stores visited max once per quarter
		for (int s = 0; s < stores.size(); s++) {
			for (int q = 0; q < 4; q++) {
				MPConstraint ct = solver.makeConstraint(0, 1);
				for (int w = 0; w < 14; w++) {
					ct.setCoefficient(x[s][q][w], 1);
				}
			}	
		}
		
		if (presolve) {
			// All stores visited the number of time as per frequency 
			for (int s = 0; s < stores.size(); s++) {
				MPConstraint ct = solver.makeConstraint(stores.get(s).getFrequency(), stores.get(s).getFrequency());
				for (int q = 0; q < 4; q++) {
					for (int w = 0; w < 14; w++) {
						ct.setCoefficient(x[s][q][w], 1);
					}
				}	
			}
		} else {
			// Force store quarter allocation based on preallocation
			for (int q = 0; q < 4; q++) {
				for (int s = 0; s < stores.size(); s++) {
					MPConstraint ct = null;
					Store store = stores.get(s);
					if (quartersAllocation.get(q).stream().filter(st -> st.getStoreNo()==store.getStoreNo()).count()>0 ) 
						ct = solver.makeConstraint(1, 1);
					else 
						ct = solver.makeConstraint(0, 0);
					for (int w = 0; w < 14; w++) {
						ct.setCoefficient(x[s][q][w], 1);
					}
				}
			}
		}
		
		// Each quarter each auditor the total no. of visits during weekends is to be at least weekendAuditsMin% of total visits
		double ratioWeekendsMin = (1-weekendAuditsMin)/weekendAuditsMin;
		for (String auditor : getAuditors(stores)) {
			for (int q = 0; q < 4; q++) {
				MPConstraint ct = solver.makeConstraint(0, Integer.MAX_VALUE);
				for (int s = 0; s < stores.size(); s++) {
					if(stores.get(s).getAuditor().equalsIgnoreCase(auditor))
						for (int w = 0; w < 14; w++) {
							if(isWeekend(w))
								ct.setCoefficient(x[s][q][w], ratioWeekendsMin);
							else 
								ct.setCoefficient(x[s][q][w], -1);
					}
				}
			}
		}
		
		// Each quarter each auditor the total no. of evening visits eveningAuditsMin% of total visits
		double ratioEveningsMin = (1-eveningAuditsMin)/eveningAuditsMin;
		for (String auditor : getAuditors(stores)) {
			for (int q = 0; q < 4; q++) {
				MPConstraint ct = solver.makeConstraint(0, Integer.MAX_VALUE);
				for (int s = 0; s < stores.size(); s++) {
					if(stores.get(s).getAuditor().equalsIgnoreCase(auditor))
						for (int w = 0; w < 14; w++) {
							if(isLunch(w))
								ct.setCoefficient(x[s][q][w], -1);
							else 
								ct.setCoefficient(x[s][q][w], ratioEveningsMin);
						}
				}
			}
		}
		
		// Each Store needs to be visited maximum once any weekday
		for (int s = 0; s < stores.size(); s++) {
			for (String day : getDays()) {
				MPConstraint ct = solver.makeConstraint(0,1);
				for (int q = 0; q < 4; q++) {
					for (Integer w : getDayParts(day)) {
						ct.setCoefficient(x[s][q][w], 1);
					}
				}	
			}
		}
		
		// Load Balance 
		// Each quarter the total no. of any weekday visits should be at least dailyAuditsMin% of total visits
		double ratioWeekdayDailyMin = (1-dailyWeekdayAuditsMin)/(dailyWeekdayAuditsMin);
		for (int q = 0; q < 4; q++) {
			for (String wd : getWeekDays()) {
				MPConstraint ct = solver.makeConstraint(0, Integer.MAX_VALUE);
				for (int s = 0; s < stores.size(); s++) {
					for (int w = 0; w < 14; w++) {
						if(wd.equalsIgnoreCase(getWeekDay(w)))
							ct.setCoefficient(x[s][q][w], ratioWeekdayDailyMin);
						else 
							ct.setCoefficient(x[s][q][w], -1);
					}
				}
			}
		}
		
		// Each quarter the total no. of any weekday visits should be at least dailyAuditsMin% of total visits
		double ratioWeekendDailyMin = (1-dailyWeekendAuditsMin)/(dailyWeekendAuditsMin);
		for (int q = 0; q < 4; q++) {
			for (String wd : getWeekends()) {
				MPConstraint ct = solver.makeConstraint(0, Integer.MAX_VALUE);
				for (int s = 0; s < stores.size(); s++) {
					for (int w = 0; w < 14; w++) {
						if(wd.equalsIgnoreCase(getWeekDay(w)))
							ct.setCoefficient(x[s][q][w], ratioWeekendDailyMin);
						else 
							ct.setCoefficient(x[s][q][w], -1);
					}
				}
			}
		}
		
		// Each quarter the total no. of visits should be at least quarterAuditsMin% of total visits
		double ratioQuarterMin = (1-quarterAuditsMin)/(quarterAuditsMin);
		//for (String auditor : getAuditors(stores)) {
			for (int q = 0; q < 4; q++) {
				MPConstraint ct = solver.makeConstraint(0, Integer.MAX_VALUE);
				for (int w = 0; w < 14; w++) {
					for (int s = 0; s < stores.size(); s++) {
						//if(stores.get(s).getAuditor().equalsIgnoreCase(auditor))
							for (int q2 = 0; q2 < 4; q2++) {
								if(q2==q)
									ct.setCoefficient(x[s][q2][w], ratioQuarterMin);
								else 
									ct.setCoefficient(x[s][q2][w], -1);
							}
					}
				}
			}
		//}
		// Each auditor each quarter each day/day part needs to have a number of visits less than max_visits_auditor_quarter_weekslot
		for (String auditor : getAuditors(stores)) {
			for (int q = 0; q < 4; q++) {
				for (int w = 0; w < 14; w++) {
					MPConstraint ct = null;
					if(isLunch(w))
						ct = solver.makeConstraint(0,max_visits_auditor_quarter_dayLunch);
					else
						ct = solver.makeConstraint(0,max_visits_auditor_quarter_dayEvening);
					for (int s = 0; s < stores.size(); s++) {
						if(stores.get(s).getAuditor().equalsIgnoreCase(auditor)) 
								ct.setCoefficient(x[s][q][w], 1);
					}
				}
			}
		}
		
		// Optimisation 
		if (!presolve) {
			// Audits in the same cluster should be conducted on same day
			clusters = new HashMap<String, Cluster>();
			// Audits in the same clusted can have a maximum of 2 lunch and 1 evening
			for (int q=0; q<4; q++) {
				for (String auditor: getAuditors(stores)) {
					Map<String, Cluster> auditorClusters = getClustersForStores(getAuditorQuarterStores(auditor, q));
					clusters.putAll(auditorClusters);
					for (Cluster cluster : auditorClusters.values()) {
						for (int si=0; si<cluster.getStores().size()-1; si++) {
							//for (int w = 0; w < 14; w++) {
							for (String day : getWeekDays()) {
								MPConstraint ct = solver.makeConstraint(0,0);
								for (Integer w : getDayParts(day)) {
									ct.setCoefficient(x[cluster.getStores().get(si).getStoreNo()][q][w], 1);
									ct.setCoefficient(x[cluster.getStores().get(si+1).getStoreNo()][q][w], -1);
								}
							}
						}
						
						MPConstraint ctl = solver.makeConstraint(0,2);
						MPConstraint cte = solver.makeConstraint(0,1);
						for (int si=0; si<cluster.getStores().size(); si++) {
							for(int w=0; w<14; w++) {
								if (isLunch(w)) {
									ctl.setCoefficient(x[cluster.getStores().get(si).getStoreNo()][q][w], 1);
								} else {
									cte.setCoefficient(x[cluster.getStores().get(si).getStoreNo()][q][w], 1);
								}
							}
						}
						
					}
				}
			}
			
			
			
		}
		
		// Objective Function: None for now
		MPObjective objective = solver.objective();
		for (int s = 0; s < stores.size(); s++) {
			for (int q = 0; q < 4; q++) {
				for (int w = 0; w < 14; w++) {
					objective.setCoefficient(x[s][q][w], 1);
				}
			}
		}
		
		logger.info("No. Audits:" + getNoAudits(stores));
		logger.info("No. Auditors:" + getAuditors(stores).size());
		logger.info("No. Variables: " + solver.numVariables());
		logger.info("No. Constraints: " + solver.numConstraints());
		
		// Solve
		solver.setTimeLimit(maxExecTime); 
		solver.solve();
		
		// Verify that the solution satisfies all constraints (when using solvers
		// others than GLOP_LINEAR_PROGRAMMING, this is highly recommended!).
		if (!solver.verifySolution(/*tolerance=*/1e-7, /*logErrors=*/true)) {
			logger.error("The solution returned by the solver violated the problem constraints by at least 1e-7");
			throw new Exception("The solution returned by the solver violated the problem constraints by at least 1e-7");
		}
		
		logger.debug("Problem solved in " + solver.wallTime() + " milliseconds");
		logger.debug("No. interations : " + solver.iterations());
		logger.debug("Problem solved in " + solver.nodes() + " branch-and-bound nodes");
		
		return x;
	}
	
	private List<Store> getAuditorQuarterStores(String auditor, int q) {
		
		return quartersAllocation.get(q).stream().filter(s -> s.getAuditor().equalsIgnoreCase(auditor)).collect(Collectors.toList());
	}
	
	private boolean isEvening(int w) {
		return !isLunch(w);
	}
	
	private boolean isLunch(int w) {
		return w%2==0;
	}
	
	private boolean isWeekend(int w) {
		return w>=9;
	}
	
	private List<String> getWeekDays() {
		List<String> weekDays = new ArrayList<String>();
		weekDays.add("Monday");
		weekDays.add("Tuesday");
		weekDays.add("Wednesday");
		weekDays.add("Thursday");
		weekDays.add("Friday");
		return weekDays;
	}
	
	private List<String> getWeekends() {
		List<String> days = new ArrayList<String>();
		days.add("Saturday");
		days.add("Sunday");
		return days;
	}
	
	private List<Integer> getDayParts(String day) {
		List<Integer> dayParts = new ArrayList<Integer>();
		if(day.equalsIgnoreCase("Monday")) {
			dayParts.add(0);
			dayParts.add(1);
			return dayParts;
		}
		if(day.equalsIgnoreCase("Tuesday")) {
			dayParts.add(2);
			dayParts.add(3);
			return dayParts;
		}
		if(day.equalsIgnoreCase("Wednesday")) {
			dayParts.add(4);
			dayParts.add(5);
			return dayParts;
		}
		if(day.equalsIgnoreCase("Thursday")) {
			dayParts.add(6);
			dayParts.add(7);
			return dayParts;
		}
		if(day.equalsIgnoreCase("Friday")) {
			dayParts.add(8);
			dayParts.add(9);
			return dayParts;
		}
		if(day.equalsIgnoreCase("Saturday")) {
			dayParts.add(10);
			dayParts.add(11);
			return dayParts;
		}
		if(day.equalsIgnoreCase("Sunday")) {
			dayParts.add(12);
			dayParts.add(13);
			return dayParts;
		}
		return dayParts;
	}
	private List<String> getDays() {
		List<String> days = new ArrayList<String>();
		days.add("Monday");
		days.add("Tuesday");
		days.add("Wednesday");
		days.add("Thursday");
		days.add("Friday");
		days.add("Saturday");
		days.add("Sunday");
		return days;
	}
	
	private String getWeekDay(int w) {
		String weekDay = "Unknown";
		switch (w) {
		case 0:
			weekDay = "Monday";
			break;
		case 1:
			weekDay = "Monday";
			break;
		case 2:
			weekDay = "Tuesday";
			break;
		case 3:
			weekDay = "Tuesday";
			break;
		case 4:
			weekDay = "Wednesday";
			break;
		case 5:
			weekDay = "Wednesday";
			break;
		case 6:
			weekDay = "Thursday";
			break;
		case 7:
			weekDay = "Thursday";
			break;
		case 8:
			weekDay = "Friday";
			break;
		case 9:
			weekDay = "Friday";
			break;
		case 10:
			weekDay = "Saturday";
			break;
		case 11:
			weekDay = "Saturday";
			break;
		case 12:
			weekDay = "Sunday";
			break;
		case 13:
			weekDay = "Sunday";
			break;
		default:
			break;
		}
		return weekDay;
	}
	
	private String getDayPart(int w) {
		String dayPart = "Unknown";
		switch (w) {
		case 0:
			dayPart = "01 Monday Lunch";
			break;
		case 1:
			dayPart = "02 Monday Evening";
			break;
		case 2:
			dayPart = "03 Tuesday Lunch";
			break;
		case 3:
			dayPart = "04 Tuesday Evening";
			break;
		case 4:
			dayPart = "05 Wednesday Lunch";
			break;
		case 5:
			dayPart = "06 Wednesday Evening";
			break;
		case 6:
			dayPart = "07 Thursday Lunch";
			break;
		case 7:
			dayPart = "08 Thursday Evening";
			break;
		case 8:
			dayPart = "09 Friday Lunch";
			break;
		case 9:
			dayPart = "10 Friday Evening";
			break;
		case 10:
			dayPart = "11 Saturday Lunch";
			break;
		case 11:
			dayPart = "12 Saturday Evening";
			break;
		case 12:
			dayPart = "13 Sunday Lunch";
			break;
		case 13:
			dayPart = "14 Sunday Evening";
			break;
		default:
			break;
		}
		return dayPart;
	}
	
	private int getNoAudits(List<Store> stores) {
		return stores.stream().mapToInt(s -> s.getFrequency()).sum();
	}
	
	private List<String> getAuditors(List<Store> stores) {
		return stores.stream().map(s -> s.getAuditor()).distinct().collect(Collectors.toList());
	}
	private static MPSolver createSolver (String solverType) {
	    try {
	      return new MPSolver("IntegerProgrammingExample", MPSolver.OptimizationProblemType.valueOf(solverType));
	    } catch (java.lang.IllegalArgumentException e) {
	      return null;
	    }
	}
	
	@Override
	public void setDbHelper(DbHelper db) {
		this.db = db;
	}

	@Override
	public void setParameters(ScheduleParameters sp) {
	//	this.sp = sp;
	}

	private void saveOutput(MPVariable[][][] x) throws IOException {
		FileInputStream tmpis = new FileInputStream(new File(inputFileName));
		Workbook tmpwb = new XSSFWorkbook(tmpis);
		Sheet tmpsh = tmpwb.getSheet("schedule");
		if (tmpsh == null)
			tmpsh = tmpwb.createSheet("schedule");
		
		Row header = tmpsh.createRow(0);
		Cell h1 = header.createCell(0); h1.setCellType(Cell.CELL_TYPE_STRING); h1.setCellValue("Store");
		Cell h2 = header.createCell(1); h2.setCellType(Cell.CELL_TYPE_STRING); h2.setCellValue("Auditor");		
		Cell h3 = header.createCell(2); h3.setCellType(Cell.CELL_TYPE_STRING); h3.setCellValue("Frequency");
		Cell h4 = header.createCell(3); h4.setCellType(Cell.CELL_TYPE_STRING); h4.setCellValue("Quarter");
		Cell h5 = header.createCell(4); h5.setCellType(Cell.CELL_TYPE_STRING); h5.setCellValue("Day Part");
		Cell h6 = header.createCell(5); h6.setCellType(Cell.CELL_TYPE_STRING); h6.setCellValue("Is Evening");
		Cell h7 = header.createCell(6); h7.setCellType(Cell.CELL_TYPE_STRING); h7.setCellValue("Is Weekend");
		Cell h8 = header.createCell(7); h8.setCellType(Cell.CELL_TYPE_STRING); h8.setCellValue("Week Day");
		Cell h9 = header.createCell(8); h9.setCellType(Cell.CELL_TYPE_STRING); h9.setCellValue("Store Cluster");
		Cell h10 = header.createCell(9); h10.setCellType(Cell.CELL_TYPE_STRING); h10.setCellValue("Address");
		Cell h11 = header.createCell(10); h11.setCellType(Cell.CELL_TYPE_STRING); h11.setCellValue("Lat");
		Cell h12 = header.createCell(11); h12.setCellType(Cell.CELL_TYPE_STRING); h12.setCellValue("Lng");
		Cell h13 = header.createCell(12); h13.setCellType(Cell.CELL_TYPE_STRING); h13.setCellValue("Km from Cluster centroid");
		int rowIndex = 1;
		for (int s = 0; s < x.length; s++) {
			for (int q = 0; q < x[0].length; q++) {
				for (int w = 0; w < x[0][0].length; w++) {
					if (x[s][q][w] != null && x[s][q][w].solutionValue()>0) {
						Row data = tmpsh.createRow(rowIndex++);
						Store store = getStoreByQuarterAndIndex(q,s);
						Cell d1 = data.createCell(0); d1.setCellType(Cell.CELL_TYPE_STRING); d1.setCellValue(store.getName());
						Cell d2 = data.createCell(1); d2.setCellType(Cell.CELL_TYPE_STRING); d2.setCellValue(store.getAuditor());
						Cell d3 = data.createCell(2); d3.setCellType(Cell.CELL_TYPE_NUMERIC); d3.setCellValue(store.getFrequency());
						Cell d4 = data.createCell(3); d4.setCellType(Cell.CELL_TYPE_NUMERIC); d4.setCellValue(q+1);
						Cell d5 = data.createCell(4); d5.setCellType(Cell.CELL_TYPE_STRING); d5.setCellValue(getDayPart(w));
						Cell d6 = data.createCell(5); d6.setCellType(Cell.CELL_TYPE_BOOLEAN); d6.setCellValue(isEvening(w));
						Cell d7 = data.createCell(6); d7.setCellType(Cell.CELL_TYPE_BOOLEAN); d7.setCellValue(isWeekend(w));
						Cell d8 = data.createCell(7); d8.setCellType(Cell.CELL_TYPE_BOOLEAN); d8.setCellValue(getWeekDay(w));
						Cell d9 = data.createCell(8); d9.setCellType(Cell.CELL_TYPE_STRING); d9.setCellValue(store.getCluster()==null?"":store.getCluster());
						Cell d10 = data.createCell(9); d10.setCellType(Cell.CELL_TYPE_STRING); d10.setCellValue(store.getAddress());
						Cell d11 = data.createCell(10); d11.setCellType(Cell.CELL_TYPE_NUMERIC); d11.setCellValue(store.getCoordinates().getLat().doubleValue());
						Cell d12 = data.createCell(11); d12.setCellType(Cell.CELL_TYPE_NUMERIC); d12.setCellValue(store.getCoordinates().getLng().doubleValue());
						Cell d13 = data.createCell(12); d13.setCellType(Cell.CELL_TYPE_NUMERIC); d13.setCellValue(
								((store.getCluster()==null)?
										-1:
										(Utility.calculateDistanceKm(
												store.getCoordinates().getLat().doubleValue(), 
												store.getCoordinates().getLng().doubleValue(), 
												clusters.get(store.getCluster()).getCentroid().getLat().doubleValue(), 
												clusters.get(store.getCluster()).getCentroid().getLng().doubleValue())) 
								));
						
						logger.debug("Store " + store.getName() + " to be audited by " + store.getAuditor() + " during quarter " + q + " and day/day part " + getDayPart(w));
					}
				}
			}
		}
		for (int s=0; s<stores.size(); s++) {
			
		}
		tmpis.close();
		
		FileOutputStream fos = new FileOutputStream(new File(inputFileName)); 
		tmpwb.write(fos);
        tmpwb.close();
        
	}
	
	private Store getStoreByQuarterAndIndex(int q, int si) {
		return quartersAllocation.get(q).stream().filter(s -> s.getStoreNo()==si).findFirst().orElse(null);
	}
	
	@Override
	public void init() throws Exception {
		// Set Solver Type
		solverType = "CBC_MIXED_INTEGER_PROGRAMMING";
		
		// Read Input data from Excel file
		stores = new ArrayList<Store>();
		FileInputStream tmpis = new FileInputStream(new File(inputFileName));
		Workbook tmpwb = new XSSFWorkbook(tmpis);
		Sheet tmpsh = tmpwb.getSheetAt(0);
				
		int rowIndex = 0, columnIndex = 0;
		for (Row tmpRow : tmpsh) {
			rowIndex = tmpRow.getRowNum();
			if (rowIndex==0) {
				// Skip header
				continue;
			}
			Store aStore = new Store();
			aStore.setStoreNo(rowIndex-1);
			for (Cell tmpCell : tmpRow) {
				columnIndex = tmpCell.getColumnIndex();
				tmpCell.getCellType();
				switch (columnIndex) {
				case 0:
					aStore.setName(tmpCell.getStringCellValue());
					break;
				case 1:
					aStore.setAuditor(tmpCell.getStringCellValue());
					break;
				case 2:
					aStore.setFrequency(new Double(tmpCell.getNumericCellValue()).intValue());
					break;
				case 3:
					aStore.setLatitude(tmpCell.getNumericCellValue());
					break;
				case 4:
					aStore.setLongitude(tmpCell.getNumericCellValue());
					break;
				case 5:
					aStore.setAddress(tmpCell.getStringCellValue(), db);
					break;
				default:
					break;
				}
			}
			if (aStore.isValid()) {
				stores.add(aStore);
			}
		}
		
		tmpwb.close();
		tmpis.close();
	}
	
	private Map<String, Cluster> getClustersForStores(List<Store> auditorStores) throws Exception {
		// Quick exit
		if(auditorStores.size()<4) {
			return new HashMap<String, Cluster>();
		}
		List<org.apache.spark.sql.Row> data = new ArrayList<org.apache.spark.sql.Row>();
		
		for (Store store : auditorStores) {
			data.add(RowFactory.create(Vectors.dense(store.getCoordinates().getLat().doubleValue(), store.getCoordinates().getLng().doubleValue())));
		}
		
		Dataset<org.apache.spark.sql.Row> dataset = spark.createDataFrame(data, schema);
		
		logger.info("Find this:"+(int) Math.floorDiv(dataset.count(), 2));
		// Trains a k-means model.
		KMeans kmeans = new KMeans().setK((int) Math.floorDiv(dataset.count(), 2)).setSeed(1L);
		KMeansModel model = kmeans.fit(dataset);

		// Evaluate clustering by computing Within Set Sum of Squared Errors.
		//double WSSSE = model.computeCost(dataset);
		//System.out.println("Within Set Sum of Squared Errors = " + WSSSE);

		Vector[] centers = model.clusterCenters();
		Map<String, Cluster> auditorClusters = new HashMap<String, Cluster>();
		for (Store store : auditorStores) {
			String auditor = store.getAuditor();
			int quarter = store.getQuarter(); 
			int clusterNo = model.predict(Vectors.dense(store.getCoordinates().getLat().doubleValue(), store.getCoordinates().getLng().doubleValue()));
			String clusterId = auditor+"-"+quarter+":"+clusterNo; 
			if (!auditorClusters.containsKey(clusterId)) {
				Cluster cluster = new Cluster();
				cluster.setClusterNo(clusterId);
				cluster.setCentroid(centers[clusterNo]);
				cluster.setAuditor(auditor);
				cluster.setStores(new ArrayList<Store>());
				auditorClusters.put(clusterId, cluster);
			}
			store.setCluster(clusterId);
			auditorClusters.get(clusterId).getStores().add(store);
		}
		
		//Comparator<Cluster> bySize = (Cluster c1, Cluster c2)->new Integer(c1.getStores().size()).compareTo(new Integer(c2.getStores().size()));
		//auditorClusters = auditorClusters.values().stream().sorted(bySize).collect(Collectors.toMap(Cluster::getClusterNo, Function.identity()));
		
		// Add store to clusters of size < 2 (i.e. 1)
		Cluster auxCluster = auditorClusters.values().stream().filter(c -> c.getStores().size()==1).findFirst().orElse(null);
		while (auxCluster != null) {
			// Find closest store to this cluster
			double cLat = auxCluster.getCentroid().getLat().doubleValue();
			double cLng = auxCluster.getCentroid().getLng().doubleValue();
			String cNo = auxCluster.getClusterNo();
			Comparator<Store> byDistanceToCentroid = (Store s1, Store s2)-> new Double(Utility.calculateDistanceKm(s1.getCoordinates().getLat().doubleValue(), s1.getCoordinates().getLng().doubleValue(), cLat, cLng))
				.compareTo(new Double(Utility.calculateDistanceKm(s2.getCoordinates().getLat().doubleValue(), s2.getCoordinates().getLng().doubleValue(), cLat, cLng)));
			Store toBeAdded = auditorClusters.values().stream()
				.filter(c -> c.getClusterNo() != cNo && c.getStores().size()!=2)
				.map(c -> c.getStores())
				.flatMap(c->c.stream())
				.sorted(byDistanceToCentroid)
				.findFirst()
				.orElse(null);
			if(toBeAdded != null && Utility.calculateDistanceKm(toBeAdded.getCoordinates().getLat().doubleValue(), toBeAdded.getCoordinates().getLng().doubleValue(), cLat, cLng) < 60) {
				// Remove it from original cluster
				auditorClusters.get(toBeAdded.getCluster()).getStores().remove(toBeAdded);
				
				
				// Add it to this cluster
				toBeAdded.setCluster(auxCluster.getClusterNo());
				auditorClusters.get(auxCluster.getClusterNo()).getStores().add(toBeAdded);
			} else {
				// Just remove this cluster from the list
				auditorClusters.get(cNo).getStores().stream().forEach(s -> s.setCluster(null));
				auditorClusters.remove(cNo);
			}
			auxCluster = auditorClusters.values().stream().filter(c -> c.getStores().size()==1).findFirst().orElse(null);
		} 
		
		auxCluster =  auditorClusters.values().stream().filter(c -> c.getStores().size()>3).findFirst().orElse(null);
		while (auxCluster != null) {
			List<Cluster> split = auxCluster.split();
			// Remove cluster
			auditorClusters.get(auxCluster.getClusterNo()).getStores().stream().forEach(s -> s.setCluster(null));
			auditorClusters.remove(auxCluster.getClusterNo());
			
			// Add splits
			for (Cluster c : split) {
				c.getStores().stream().forEach(s -> s.setCluster(c.getClusterNo()));
				auditorClusters.put(c.getClusterNo(), c);
			}
			auxCluster =  auditorClusters.values().stream().filter(c -> c.getStores().size()>3).findFirst().orElse(null);
		}
		
		
		// Reports clusters with size >=2
		auditorClusters = auditorClusters.values().stream().filter(c -> c.getStores().size()>=2).collect(Collectors.toMap(Cluster::getClusterNo, Function.identity()));
		return auditorClusters;
	}
}

class Cluster {
	private List<Store> stores = null;
	private LatLng centroid = null;
	private String clusterNo;
	private String auditor;
	public List<Store> getStores() {
		return stores;
	}
	public void setStores(List<Store> stores) {
		this.stores = stores;
	}
	public LatLng getCentroid() {
		if (centroid == null) 
			calculateCentroid();
		return centroid;
	}
	public void setCentroid(LatLng centroid) {
		this.centroid = centroid;
	}
	
	public void setCentroid(Vector v) throws Exception {
		if (v.toArray().length==2) {
			this.centroid = new LatLng();
			this.centroid.setLat(new BigDecimal(v.toArray()[0]));
			this.centroid.setLng(new BigDecimal(v.toArray()[1]));
		} else {
			throw new Exception("Vector does not represent coordinatess");
		}
	}
	
	public String getClusterNo() {
		return clusterNo;
	}
	public void setClusterNo(String clusterNo) {
		this.clusterNo = clusterNo;
	}
	public String getAuditor() {
		return auditor;
	}
	public void setAuditor(String auditor) {
		this.auditor = auditor;
	}
	
	public List<Cluster> split() {
		// If cluster has more than 3 stores split it into two sub-clusters with max 2 or 3 stores
		List<Store> visited = new ArrayList<Store>();
		visited.add(this.stores.get(0));
		while (visited.size()<this.stores.size()) {
			Comparator<Store> byDistanceToLast = (Store s1, Store s2)-> new Double(Utility.calculateDistanceKm(s1.getCoordinates().getLat().doubleValue(), s1.getCoordinates().getLng().doubleValue(), visited.get(visited.size()-1).getCoordinates().getLat().doubleValue(), visited.get(visited.size()-1).getCoordinates().getLng().doubleValue()))
				.compareTo(new Double(Utility.calculateDistanceKm(s2.getCoordinates().getLat().doubleValue(), s2.getCoordinates().getLng().doubleValue(), visited.get(visited.size()-1).getCoordinates().getLat().doubleValue(), visited.get(visited.size()-1).getCoordinates().getLng().doubleValue())));
			visited.add(this.stores.stream().filter(s -> !visited.contains(s)).sorted(byDistanceToLast).findFirst().get());
		}
		
		int subClusterNo = 0;
		List<Cluster> split = new ArrayList<Cluster>();
		while (visited.size()>0) {
			if (split.size()==0 || (split.get(split.size()-1).stores.size()==2 && visited.size()>1)) {
				Cluster subCluster = new Cluster();
				subCluster.setClusterNo(this.clusterNo+":"+subClusterNo++);
				subCluster.setAuditor(this.getAuditor());
				subCluster.setStores(new ArrayList<Store>());
				split.add(subCluster);
			}
			visited.get(0).setCluster(split.get(split.size()-1).getClusterNo());
			split.get(split.size()-1).stores.add(visited.get(0));
			visited.remove(0);
		}
		return split;
	}
	
	private void calculateCentroid() {
		this.centroid = new LatLng();
		this.centroid.setLat(new BigDecimal(stores.stream().mapToDouble(s -> s.getCoordinates().getLat().doubleValue()).sum()/stores.size()));
		this.centroid.setLng(new BigDecimal(stores.stream().mapToDouble(s -> s.getCoordinates().getLng().doubleValue()).sum()/stores.size()));
	}
	
	@Override
	public boolean equals(Object other) {
		if (other != null && this != null && other instanceof Cluster && this.clusterNo.equalsIgnoreCase(((Cluster)other).getClusterNo()))
			return true;
		else 
			return false;
	}
}

class Store {
	private String name = null, auditor = null, address = null;
	private int frequency = 0;
	private int quarter = 0;
	private String cluster = null;
	private int storeNo = -1;
	private LatLng coordinates = null;
	public boolean isValid() {
		return name != null && auditor != null && frequency >0;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getAuditor() {
		return auditor;
	}
	public void setAuditor(String auditor) {
		this.auditor = auditor;
	}
	public int getFrequency() {
		return frequency;
	}
	public void setFrequency(int frequency) {
		this.frequency = frequency;
	}
	
	public String getAddress() {
		return address;
	}
	public void setLatitude(double l) {
		if (this.coordinates == null) 
			this.coordinates = new LatLng();
		
		this.coordinates.setLat(new BigDecimal(l));
	}
	
	public void setLongitude(double l) {
		if (this.coordinates == null) 
			this.coordinates = new LatLng();
		
		this.coordinates.setLng(new BigDecimal(l));
	}
	
	public void setAddress(String address, DbHelper db) {
		this.address = address;
		if (this.coordinates == null) {
			try {
				this.coordinates = Utility.getGeocode(this.address, this.address, db);
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}
	public Store(String name, String auditor, int frequency) {
		super();
		this.name = name;
		this.auditor = auditor;
		this.frequency = frequency;
	}
	public Store() {
		super();
	}
	public LatLng getCoordinates() {
		return coordinates;
	}
	public String getCluster() {
		return cluster;
	}
	public void setCluster(String cluster) {
		this.cluster = cluster;
	}
	public int getStoreNo() {
		return storeNo;
	}
	public void setStoreNo(int storeNo) {
		this.storeNo = storeNo;
	}
	@Override
	public boolean equals(Object other) {
		if (other != null && this != null && other instanceof Store &&  this.getStoreNo()==((Store)other).getStoreNo())
			return true;
		else 
			return false;
	}
	public int getQuarter() {
		return quarter;
	}
	public void setQuarter(int quarter) {
		this.quarter = quarter;
	}
}