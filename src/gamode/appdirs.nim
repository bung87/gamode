import os
import strutils

type
    TAppl* = object
        name*: string
        author*: string
        version*: string
        use_roaming*: bool

# USEFUL PROCS

proc getPlatform(platform: string): string {.inline noSideEffect.} =
    if platform == "":
        return hostOS
    else:
        return platform

proc emptyExists(name: string): bool {.inline.} =
    if not os.existsEnv(name):
        return false
    else:
        return os.getEnv(name).strip() != ""


# TAPPL CONSTRUCTOR

proc application*(name: string, author: string, version: string,
        roaming: bool = false): TAppl =
    ## Constructs a TAppl object with given args.
    ##
    ## The only required arg is `name`.  If `author` is not given, it defaults to `name`.  This is only
    ## used on Windows machines, in which case the application directory will sit inside the author
    ## directory.  On other platforms, `author` is ignored.
    ##
    ## If `version` is given, it is appended to any resultant directory.  This allows an application to
    ## have multiple versions installed on one computer.
    ##
    ## The `roaming` arg is also for Windows systems only, and decides if the directory can be shared
    ## on any computer in a Windows network (roaming=true) or if it will be kept locally
    ## (roaming=false).  Note that the cache and logs directory will always be kept locally.

    var auth: string
    if author == "":
        auth = name
    else:
        auth = author

    result = TAppl(name: name, author: auth, version: version,
            use_roaming: roaming)


# USER DATA

proc userData*(roaming: bool = false, platform: string): string =
    ## Returns the generic user data directory for a given platform.
    ## The platform defaults to the current platform.

    var plat = getPlatform(platform)

    if plat == "macosx":
        return os.joinPath(os.getEnv("HOME"), "Library", "Application Support")
    elif plat == "windows":
        if (not roaming) and os.existsEnv("LOCALAPPDATA"):
            return os.getEnv("APPDATA")
        else:
            return os.getEnv("LOCALAPPDATA")
    else:
        if emptyExists("XDG_DATA_HOME"):
            return os.getEnv("XDG_DATA_HOME")
        else:
            return os.joinPath(os.getEnv("HOME"), ".local", "share")

proc userData*(appl: TAppl, platform: string): string =
    ## Returns the user data directory for a given app for a given platform.
    ## The platform defaults to the current platform.

    var path = userData(appl.use_roaming, platform)

    if getPlatform(platform) == "windows":
        path = os.joinPath(path, appl.author, appl.name)
    else:
        path = os.joinPath(path, appl.name)

    if appl.version != "":
        path = os.joinPath(path, appl.version)

    return path

proc userData*(name: string, author: string, version: string,
        roaming: bool = false, platform: string): string =
    ## Gets the data directory given the details of an application.
    ## This proc creates an application from the arguments, and uses it to call the
    ## `userData(TAppl)` proc.
    return application(name, author, version, roaming).userData(platform)


# USER CONFIG

proc userConfig*(roaming: bool = false, platform: string): string =
    ## Returns the generic user config directory for a given platform.
    ## The platform defaults to the current platform.

    var plat = getPlatform(platform)

    if plat == "macosx" or plat == "windows":
        return userData(roaming, plat)
    else:
        if emptyExists("XDG_CONFIG_HOME"):
            return os.getEnv("XDG_CONFIG_HOME")
        else:
            return os.joinPath(os.getEnv("HOME"), ".config")

proc userConfig*(appl: TAppl, platform: string): string =
    ## Returns the user config directory for a given app for a given platform.
    ## The platform defaults to the current platform.

    var path = userConfig(appl.use_roaming, platform)

    if getPlatform(platform) == "windows":
        path = os.joinPath(path, appl.author, appl.name)
    else:
        path = os.joinPath(path, appl.name)

    if appl.version != "":
        path = os.joinPath(path, appl.version)

    return path

proc userConfig*(name: string, author: string, version: string,
        roaming: bool = false, platform: string): string =
    ## Gets the config directory given the details of an application.
    ## This proc creates an application from the arguments, and uses it to call the
    ## `userConfig(TAppl)` proc.
    return application(name, author, version, roaming).userConfig(platform)


# USER CACHE

proc genericUserCache(platform: string): string =
    ## Gets the local users' cache directory.
    ##
    ## Note, on Windows there is no "official" cache directory, so instead this procedure
    ## returns the users's Application Data folder.    Use the `userCache(TAppl)` version
    ## to with `force_cache = true` to add an artifical `Cache` directory inside your
    ## main appdata directory.
    ##
    ## On all other platforms, there is a cache directory to use.

    var plat = getPlatform(platform)

    if plat == "windows":
        return userData(false, platform)

    elif plat == "macosx":
        return os.joinPath(os.getEnv("HOME"), "Library", "Caches")

    else:
        if emptyExists("XDG_CACHE_HOME"):
            return os.getEnv("XDG_CACHE_HOME")
        else:
            return os.joinPath(os.getEnv("HOME"), ".cache")

proc userCache*(appl: TAppl, force_cache: bool = true,
        platform: string = ""): string =
    ## Gets the cache directory for a given application.
    ##
    ## Note, on Windows there is no "official" cache directory, so instead this procedure
    ## returns this application's Application Data folder.  If `force_cache = true` (the
    ## default) this procedure will add an artificial `Cache` directory inside the app's
    ## appdata folder.  Otherwise, this just returns the user's app data directory.
    ##
    ## On all other platforms, there is a cache directory to use.

    var path = genericUserCache(platform)

    if getPlatform(platform) == "windows":
        path = os.joinPath(path, appl.author, appl.name)

        if force_cache: # Be assertive, give windows users a real cache dir
            path = os.joinPath(path, "Cache")

    else:
        path = os.joinPath(path, appl.name)

    if appl.version != "":
        path = os.joinPath(path, appl.version)

    return path

proc userCache*(name: string ="", author: string ="", version: string ="",
        roaming: bool = false, force_cache: bool = true, platform: string =""): string =
    ## Gets the cache directory given the details of an application.
    ## This proc creates an application from the arguments, and uses it to call the
    ## `userCache(TAppl)` proc.

    return application(name, author, version, roaming).userCache(force_cache, platform)


# USER LOGS

proc genericUserLogs(platform: string): string =
    ## Gets the logs directory for a given platform.
    ##
    ## Note that the only platform for which there is an official user logs directory
    ## is macosx.  On Windows, this proc returns the non-roaming user data directory,
    ## while for UNIX-y platforms this proc returns the cache directory.  See the
    ## `TAppl` version of this proc for more details.
    var plat = getPlatform(platform)

    if plat == "windows":
        return userData(false, platform)
    elif plat == "macosx":
        return os.joinPath(os.getEnv("HOME"), "Library", "Logs")
    else:
        return userCache(platform)

proc userLogs*(appl: TAppl, force_logs: bool = true,
        platform: string): string =
    ## Gets the logs directory for a platform given application details.
    ##
    ## Note that the only platform for which there is an official user logs directory
    ## is macosx.  Otherwise, this returns the user data directory (for Windows) or the
    ## user cache directory (UNIX-y platforms), with a "logs" directory appended.
    ##
    ## If force_logs is passed in and evaluates to false, this proc does not append
    ## the extra "logs" directory.

    var path = genericUserLogs(platform)

    if getPlatform(platform) == "windows":
        path = os.joinPath(path, appl.author, appl.name)

        if force_logs:
            path = os.joinPath(path, "Logs")

    else:
        path = os.joinPath(path, appl.name)

        if getPlatform(platform) != "macosx" and force_logs:
            path = os.joinPath(path, "logs")

    if appl.version != "":
        path = os.joinPath(path, appl.version)

    return path

proc userLogs*(name: string, author: string, version: string,
        roaming: bool = false, force_logs: bool = true, platform: string =""): string =
    ## Gets the logs directory given the details of an application.
    ## This proc creates an application from the arguments, and uses it to call the
    ## `userLogs(TAppl)` proc.z

    return application(name, author, version, roaming).userLogs(force_logs, platform)

when isMainModule:
    echo userLogs("gamode", "bung", "0.1.0")
