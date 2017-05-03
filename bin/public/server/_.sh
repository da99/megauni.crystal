
# === {{CMD}} dev
# === {{CMD}} grace
server () {
  case "$@" in

    grace)
      local +x cmd="tmp/$APP_NAME"
      pkill -f "$cmd" || :
      if pgrep $cmd ; then
        echo "=== Could not pkill: $cmd";
      fi
      ;;

    dev)
      sh_color YELLOW "=== Running server: {{$@}} ..."
      tmp/$APP_NAME
      ;;

    *)
      echo "!!! Invalid option: $@" >&2
      exit 2
      ;;

  esac
} # === end function
