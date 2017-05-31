package com.saiglobal.sf.core.utility.dynamiccode;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import javax.tools.Diagnostic;
import javax.tools.DiagnosticCollector;
import javax.tools.JavaCompiler;
import javax.tools.JavaFileObject;
import javax.tools.StandardJavaFileManager;
import javax.tools.ToolProvider;

public class DynamicJavaCode {
	
	public static DynamicJavaCodeInterface getDynamicJavaCodeImplementation(String code, String className) throws Exception {
		
		DynamicJavaCodeInterface retValue = null;
		String fileName = DynamicJavaCode.class.getPackage().getName().replace(".", "/") + "/" + className;
		File implementation = new File(fileName + ".java");
	    if (implementation.getParentFile().exists() || implementation.getParentFile().mkdirs()) {
	        try {
	            Writer writer = null;
	            try {
	                writer = new FileWriter(implementation);
	                writer.write(code);
	                writer.flush();
	            } finally {
	                writer.close();
	            }
	
	            // Compilation Requirements
	            DiagnosticCollector<JavaFileObject> diagnostics = new DiagnosticCollector<JavaFileObject>();
	            JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
	            StandardJavaFileManager fileManager = compiler.getStandardFileManager(diagnostics, null, null);
	
	            // This sets up the class path that the compiler will use.
	            List<String> optionList = new ArrayList<String>();
	            optionList.add("-classpath");
	            optionList.add(System.getProperty("java.class.path"));// + ";C:\\SAI\\lib\\*");
	            
	            Iterable<? extends JavaFileObject> compilationUnit = fileManager.getJavaFileObjectsFromFiles(Arrays.asList(implementation));
	            JavaCompiler.CompilationTask task = compiler.getTask(null, fileManager, diagnostics, optionList, null, compilationUnit);
	            
	            // Compilation Requirements 
	            if (task.call()) {
	                // Load 
	                // Create a new custom class loader, pointing to the directory that contains the compiled
	                // classes, this should point to the top of the package structure!
	                URLClassLoader classLoader = new URLClassLoader(new URL[]{new File("./").toURI().toURL()});
	                // Load the class from the classloader by name....
	                Class<?> loadedClass = classLoader.loadClass(fileName.replace("/", "."));
	                classLoader.close();
	                // Create a new instance...
	                Object obj = loadedClass.newInstance();
	                // Santity check
	                if (obj instanceof DynamicJavaCodeInterface) {
	                    // Cast to the DynamicJavaCodeInterface interface
	                	retValue  = (DynamicJavaCodeInterface)obj;
	                }
	            } else {
	                for (Diagnostic<? extends JavaFileObject> diagnostic : diagnostics.getDiagnostics()) {
	                	System.out.println("Error on line " + diagnostic.getLineNumber() + " in " + diagnostic.getSource().toUri() + "\n" + diagnostic.getMessage(null));
	                    throw new Exception("Error on line " + diagnostic.getLineNumber() + " in " + diagnostic.getSource().toUri() + "\n" + diagnostic.getMessage(null));
	                }
	            }
	            fileManager.close();
	        } catch (IOException | ClassNotFoundException | InstantiationException | IllegalAccessException exp) {
	            throw exp;
	        }
	    }
	    return retValue;
    }

    
	public static void executeDynamicCode(String code, HashMap<String, Object> values, String className) throws Exception {
		getDynamicJavaCodeImplementation(code, className).execute(values);
	}
	
	public static void main(String[] args) throws Exception {
		// This is just a test.
		StringBuilder sb = new StringBuilder(64);
        sb.append("package com.saiglobal.sf.core.utility;\n");
        sb.append("public class DynamicJavaCodeImplementation implements com.saiglobal.sf.core.utility.DynamicJavaCodeInterface {\n");
        sb.append("    public void execute() {\n");
        sb.append("        System.out.println(\"Hello world\");\n");
        sb.append("    }\n");
        sb.append("}\n");
		executeDynamicCode(sb.toString(), null, "Hello World");
	}
}
