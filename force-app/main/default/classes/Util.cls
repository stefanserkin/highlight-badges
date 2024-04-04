/************************************************************************
 * @description Highlight Badges utilities
 *  Handle namespaces in dev vs qa/prod environments
 * 
 * @author SerkinSolutions
 * @date 2024
 ************************************************************************/
public inherited sharing class Util {
    private static String namespace {
        get {
            if (namespace == null) {
                namespace = getNamespace();
            }
            return namespace;
        }
        set;
    }

    public static String getNamespace() {
        String className = Util.class.getName();
        return className.contains('.') ? className.substringBefore('.') : '';
    }

    public static String prefixCacheNamespace(String value) {
        return String.isBlank(namespace) ? 'local.' + value : namespace + '.' + value;
    }

    /*
    public static String prefixNamespace(String value) {
        return String.isBlank(namespace) ? value : namespace + '__' + value;
    }

    public static String prefixClassNamespace(String className) {
        return String.isBlank(namespace) ? className : namespace + '.' + className;
    }
    */

}