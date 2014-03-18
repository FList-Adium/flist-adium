#include "f-list_adium.h"

//TODO: fix these up so they're only one function ...

gboolean flist_channel_activate_real(const gchar *host, const gchar *path) {
    PurpleAccount *pa;
    PurpleConnection *pc;
    GHashTable *components;
    
    purple_debug_info("flist", "We are attempting to join a channel. Account: %s Channel: %s\n", host, path);
    pa = flist_deserialize_account(host);
    if(!pa) {
        purple_debug_warning("flist", "Attempt failed. The account is not found.");
        return FALSE;
    }
    
    pc = purple_account_get_connection(pa);
    if(!pc) {
        purple_debug_warning("flist", "Attempt failed. The account has no connection.");
        return FALSE;
    }
    if(purple_connection_get_state(pc) != PURPLE_CONNECTED) {
        purple_debug_warning("flist", "Attempt failed. The account is not online.");
        return FALSE;
    }
    
    components = g_hash_table_new_full(g_str_hash, g_str_equal, NULL, NULL);
    g_hash_table_insert(components, (gpointer) "channel", (gpointer) purple_url_decode(path));
    flist_join_channel(pc, components);
    g_hash_table_destroy(components);
    
    return TRUE;
}

gboolean flist_staff_activate_real(const gchar *host, const gchar *path) {
    PurpleAccount *pa;
    PurpleConnection *pc;
    
    purple_debug_info("flist", "We are attempting to send a staff confirmation. Account: %s Callid: %s\n", host, path);
    pa = flist_deserialize_account(host);
    if(!pa) {
        purple_debug_warning("flist", "Attempt failed. The account is not found.");
        return FALSE;
    }
    
    pc = purple_account_get_connection(pa);
    if(!pc) {
        purple_debug_warning("flist", "Attempt failed. The account has no connection.");
        return FALSE;
    }
    if(purple_connection_get_state(pc) != PURPLE_CONNECTED) {
        purple_debug_warning("flist", "Attempt failed. The account is not online.");
        return FALSE;
    }
    
    flist_send_sfc_confirm(pc, path);
    
    return TRUE;
}