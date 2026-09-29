import java.nio.file.Files;
import java.nio.file.Path;
import java.lang.reflect.Method;
import java.util.Arrays;

// Reflection lets the host JDK compile this runner even when the game's jar
// targets a newer Java release. Execution uses the game's bundled runtime.
public final class RunLua {
    public static void main(String[] args) throws Exception {
        Class<?> platformClass = Class.forName("se.krka.kahlua.j2se.J2SEPlatform");
        Class<?> platformInterface = Class.forName("se.krka.kahlua.vm.Platform");
        Class<?> tableClass = Class.forName("se.krka.kahlua.vm.KahluaTable");
        Class<?> threadClass = Class.forName("se.krka.kahlua.vm.KahluaThread");
        Class<?> compilerClass = Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler");
        Object platform = platformClass.getMethod("getInstance").invoke(null);
        Object environment = platformClass.getMethod("newEnvironment").invoke(platform);
        Object thread = threadClass.getConstructor(platformInterface, tableClass)
            .newInstance(platform, environment);
        threadClass.getField("debugOwnerThread").set(thread, Thread.currentThread());
        Method compile = compilerClass.getMethod("loadstring", String.class, String.class, tableClass);
        Method call = threadClass.getMethod("pcall", Object.class, Object[].class);
        int errorsBefore = threadClass.getField("errorCount").getInt(null);
        for (String file : args) {
            Object closure = compile.invoke(null, Files.readString(Path.of(file)), file, environment);
            Object[] result = (Object[]) call.invoke(thread, closure, new Object[0]);
            if (!Boolean.TRUE.equals(result[0])) {
                throw new AssertionError(file + ": " + Arrays.toString(result));
            }
            if (result.length > 1 && result[1] instanceof String) {
                System.out.println(result[1]);
            }
        }
        int reportedErrors = threadClass.getField("errorCount").getInt(null) - errorsBefore;
        int expectedErrors = Integer.getInteger("auxilia.expectedKahluaErrors", 0);
        if (reportedErrors != expectedErrors) {
            throw new AssertionError("Kahlua reported " + reportedErrors
                + " errors; expected " + expectedErrors);
        }
        System.out.println("Lua integration checks passed.");
    }
}
