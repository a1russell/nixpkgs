args @ { fetchurl, ... }:
rec {
  baseName = ''hunchentoot'';
  version = ''v1.2.37'';

  description = ''Hunchentoot is a HTTP server based on USOCKET and
  BORDEAUX-THREADS.  It supports HTTP 1.1, serves static files, has a
  simple framework for user-defined handlers and can be extended
  through subclassing.'';

  deps = [ args."bordeaux-threads" args."chunga" args."cl+ssl" args."cl-base64" args."cl-fad" args."cl-ppcre" args."flexi-streams" args."md5" args."rfc2388" args."trivial-backtrace" args."usocket" ];

  src = fetchurl {
    url = ''http://beta.quicklisp.org/archive/hunchentoot/2017-07-25/hunchentoot-v1.2.37.tgz'';
    sha256 = ''1r0p8qasd2zy9a8l58jysz5bb1gj79cz2ikr93in0my8q44pg9lc'';
  };
    
  packageName = "hunchentoot";

  overrides = x: {
    postInstall = ''
      find "$out/lib/common-lisp/" -name '*.asd' | grep -iv '/hunchentoot[.]asd${"$"}' |
        while read f; do
          env -i \
          NIX_LISP="$NIX_LISP" \
          NIX_LISP_PRELAUNCH_HOOK="nix_lisp_run_single_form '(progn
            (asdf:load-system :$(basename "$f" .asd))
            (asdf:perform (quote asdf:compile-bundle-op) :$(basename "$f" .asd))
            (ignore-errors (asdf:perform (quote asdf:deliver-asd-op) :$(basename "$f" .asd)))
            )'" \
            "$out"/bin/*-lisp-launcher.sh ||
          mv "$f"{,.sibling}; done || true
    '';
  };
}
/* (SYSTEM hunchentoot DESCRIPTION Hunchentoot is a HTTP server based on USOCKET and
  BORDEAUX-THREADS.  It supports HTTP 1.1, serves static files, has a
  simple framework for user-defined handlers and can be extended
  through subclassing.
    SHA256 1r0p8qasd2zy9a8l58jysz5bb1gj79cz2ikr93in0my8q44pg9lc URL http://beta.quicklisp.org/archive/hunchentoot/2017-07-25/hunchentoot-v1.2.37.tgz MD5
    3fd6a6c4dd0d32db7b71828b52494325 NAME hunchentoot TESTNAME NIL FILENAME hunchentoot DEPS
    ((NAME bordeaux-threads FILENAME bordeaux-threads) (NAME chunga FILENAME chunga) (NAME cl+ssl FILENAME cl+ssl) (NAME cl-base64 FILENAME cl-base64)
     (NAME cl-fad FILENAME cl-fad) (NAME cl-ppcre FILENAME cl-ppcre) (NAME flexi-streams FILENAME flexi-streams) (NAME md5 FILENAME md5)
     (NAME rfc2388 FILENAME rfc2388) (NAME trivial-backtrace FILENAME trivial-backtrace) (NAME usocket FILENAME usocket))
    DEPENDENCIES (bordeaux-threads chunga cl+ssl cl-base64 cl-fad cl-ppcre flexi-streams md5 rfc2388 trivial-backtrace usocket) VERSION v1.2.37 SIBLINGS NIL) */
