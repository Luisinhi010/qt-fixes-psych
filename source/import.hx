#if (!macro)
import Paths;
import lore.Locale;
#end

// source/lore/Locale.hx:5: characters 8-19 : You cannot access the sys package while targeting js (for sys.io.File)
// e:\source codes\qt-fixes-new-psych\source\import.hx:2: characters 8-19 : ... referenced here
// e:\source codes\qt-fixes-new-psych\source\import.hx:1: characters 8-13 : ... referenced here //???
// it was auto-compiling to html wtf?
// nah i cant complain anymore
