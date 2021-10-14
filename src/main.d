import std.file: read;
import std.process: Config, spawnProcess;
import std.stdio: File;

import dutils.format: format, print;
import dutils.path: Path;
import dutils.toml;


version (Windows) immutable(string) DEV_NULL = "NUL:";
version (Posix)   immutable(string) DEV_NULL = "/dev/null";

class AppConfigError : Exception
{
  this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
  {
    super(msg, file, line, nextInChain);
  }
}

class AppConfig
{
  public this()
  {
  }

  public Path get(const string app)
  {
    string * path = app in apps_;
    if (path is null)
      throw new AppConfigError("unrecognized app: '{}'".format(app));
    return Path(*path);
  }

  static public AppConfig load(const Path app)
  {
    auto cfgFile = Path.home / ".config" / "jetbrains.toml";

    TOMLDocument doc;
    try
    {
      doc = parseTOML(cast(string) read(cfgFile.toString()));
    }
    catch (TOMLException ex)
    {
      throw new AppConfigError("exception processing config file '{}': {}".format(cfgFile, ex.msg));
    }

    string os = null;
    version (Windows) os = "windows";
    version (linux)   os = "linux";
    version (OSX)     os = "darwin";

    if (os is null)
      throw new AppConfigError("unrecognized operating system");

    auto config = new AppConfig();
    foreach (string key, TOMLValue value; doc.table[os])
      config.apps_[key] = value.get!string;

    return config;
  }

  private string[string] apps_;
}


void start(string[] args, Path logFile)
{
  auto logStream = File(logFile, "w");
  scope(exit) logStream.close();

  auto devNullStream = File(DEV_NULL, "r");
  scope(exit) devNullStream.close();

  spawnProcess(args, devNullStream, logStream, logStream, null, Config.detached);
}


int main(string[] args)
{
  auto app = Path(args[0]);
  auto logDir = Path.home / ".local" / "log";
  auto logFile = logDir / app.withSuffix(".log").name;

  int result = 0;

  try
  {
    auto config = AppConfig.load(app);
    auto jetbrainsAppPath = config.get(app.stem);
    string[] cmd = [jetbrainsAppPath];
    if (args.length > 1)
      cmd ~= args[1..$];
    start(cmd, logFile);
  }
  catch (Exception ex)
  {
    print("{}", ex.msg);
    result = 1;
  }

  return result;
}
