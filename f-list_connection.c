/*
 * F-List Pidgin - a libpurple protocol plugin for F-Chat
 *
 * Copyright 2011 F-List Pidgin developers.
 *
 * This file is part of F-List Pidgin.
 *
 * F-List Pidgin is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * F-List Pidgin is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with F-List Pidgin.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 *
 * This code uses large amounts of code from https://github.com/payden/libws
 * because the original Websockets implementation here was a) deprecated and
 * b) horrible and kludgy so it wasn't even technically up to spec. libws is
 * also GPL.
 *
 */


#include "f-list_connection.h"
#include <stdio.h>
#include <string.h>
#include <openssl/sha.h>
#include <stdlib.h>
#include <connection.h>

/* disconnect after 90 seconds without a ping response */
#define FLIST_TIMEOUT 90
/* how often we request a new ticket for the API */
#define FLIST_TICKET_TIMER_TIMEOUT 600



/**
 * characters used for Base64 encoding
 */
const char *BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/**
 * encode three bytes using base64 (RFC 3548)
 *
 * @param triple three bytes that should be encoded
 * @param result buffer of four characters where the result is stored
 */
void _base64_encode_triple(unsigned char triple[3], char result[4])
{
    int tripleValue, i;
    
    tripleValue = triple[0];
    tripleValue *= 256;
    tripleValue += triple[1];
    tripleValue *= 256;
    tripleValue += triple[2];
    
    for (i=0; i<4; i++)
    {
        result[3-i] = BASE64_CHARS[tripleValue%64];
        tripleValue /= 64;
    }
}

/**
 * encode an array of bytes using Base64 (RFC 3548)
 *
 * @param source the source buffer
 * @param sourcelen the length of the source buffer
 * @param target the target buffer
 * @param targetlen the length of the target buffer
 * @return 1 on success, 0 otherwise
 */
int base64_encode(unsigned char *source, size_t sourcelen, char *target, size_t targetlen)
{
    /* check if the result will fit in the target buffer */
    if ((sourcelen+2)/3*4 > targetlen-1)
        return 0;
    
    /* encode all full triples */
    while (sourcelen >= 3)
    {
        _base64_encode_triple(source, target);
        sourcelen -= 3;
        source += 3;
        target += 4;
    }
    
    /* encode the last one or two characters */
    if (sourcelen > 0)
    {
        unsigned char temp[3];
        memset(temp, 0, sizeof(temp));
        memcpy(temp, source, sourcelen);
        _base64_encode_triple(temp, target);
        target[3] = '=';
        if (sourcelen == 1)
            target[2] = '=';
        
        target += 4;
    }
    
    /* terminate the string */
    target[0] = 0;
    
    return 1;
}

/**
 * determine the value of a base64 encoding character
 *
 * @param base64char the character of which the value is searched
 * @return the value in case of success (0-63), -1 on failure
 */
int _base64_char_value(char base64char)
{
    if (base64char >= 'A' && base64char <= 'Z')
        return base64char-'A';
    if (base64char >= 'a' && base64char <= 'z')
        return base64char-'a'+26;
    if (base64char >= '0' && base64char <= '9')
        return base64char-'0'+2*26;
    if (base64char == '+')
        return 2*26+10;
    if (base64char == '/')
        return 2*26+11;
    return -1;
}

/**
 * decode a 4 char base64 encoded byte triple
 *
 * @param quadruple the 4 characters that should be decoded
 * @param result the decoded data
 * @return lenth of the result (1, 2 or 3), 0 on failure
 */
int _base64_decode_triple(char quadruple[4], unsigned char *result)
{
    int i, triple_value, bytes_to_decode = 3, only_equals_yet = 1;
    int char_value[4];
    
    for (i=0; i<4; i++)
        char_value[i] = _base64_char_value(quadruple[i]);
    
    /* check if the characters are valid */
    for (i=3; i>=0; i--)
    {
        if (char_value[i]<0)
        {
            if (only_equals_yet && quadruple[i]=='=')
            {
                /* we will ignore this character anyway, make it something
                 * that does not break our calculations */
                char_value[i]=0;
                bytes_to_decode--;
                continue;
            }
            return 0;
        }
        /* after we got a real character, no other '=' are allowed anymore */
        only_equals_yet = 0;
    }
    
    /* if we got "====" as input, bytes_to_decode is -1 */
    if (bytes_to_decode < 0)
        bytes_to_decode = 0;
    
    /* make one big value out of the partial values */
    triple_value = char_value[0];
    triple_value *= 64;
    triple_value += char_value[1];
    triple_value *= 64;
    triple_value += char_value[2];
    triple_value *= 64;
    triple_value += char_value[3];
    
    /* break the big value into bytes */
    for (i=bytes_to_decode; i<3; i++)
        triple_value /= 256;
    for (i=bytes_to_decode-1; i>=0; i--)
    {
        result[i] = triple_value%256;
        triple_value /= 256;
    }
    
    return bytes_to_decode;
}

/**
 * decode base64 encoded data
 *
 * @param source the encoded data (zero terminated)
 * @param target pointer to the target buffer
 * @param targetlen length of the target buffer
 * @return length of converted data on success, -1 otherwise
 */
size_t base64_decode(char *source, unsigned char *target, size_t targetlen)
{
    char *src, *tmpptr;
    char quadruple[4], tmpresult[3];
    int i, tmplen = 3;
    size_t converted = 0;
    
    /* concatinate '===' to the source to handle unpadded base64 data */
    src = (char *)malloc(strlen(source)+5);
    if (src == NULL)
        return -1;
    strcpy(src, source);
    strcat(src, "====");
    tmpptr = src;
    
    /* convert as long as we get a full result */
    while (tmplen == 3)
    {
        /* get 4 characters to convert */
        for (i=0; i<4; i++)
        {
            /* skip invalid characters - we won't reach the end */
            while (*tmpptr != '=' && _base64_char_value(*tmpptr)<0)
                tmpptr++;
            
            quadruple[i] = *(tmpptr++);
        }
        
        /* convert the characters */
        tmplen = _base64_decode_triple(quadruple, tmpresult);
        
        /* check if the fit in the result buffer */
        if (targetlen < tmplen)
        {
            free(src);
            return -1;
        }
        
        /* put the partial result in the result buffer */
        memcpy(target, tmpresult, tmplen);
        target += tmplen;
        targetlen -= tmplen;
        converted += tmplen;
    }
    
    free(src);
    return converted;
}


GHashTable *ticket_table;
const gchar *flist_get_ticket(FListAccount *fla) {
    return g_hash_table_lookup(ticket_table, fla->username);
}

static gboolean flist_disconnect_cb(gpointer user_data) {
    PurpleConnection *pc = user_data;
    FListAccount *fla = pc->proto_data;
    
    fla->ping_timeout_handle = 0;
    
    purple_connection_error_reason(pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "Connection timed out.");
    
    return FALSE;
}

void flist_receive_ping(PurpleConnection *pc) {
    FListAccount *fla = pc->proto_data;
    
    if(fla->ping_timeout_handle) {
        purple_timeout_remove(fla->ping_timeout_handle);
    }
    fla->ping_timeout_handle = purple_timeout_add_seconds(FLIST_TIMEOUT, flist_disconnect_cb, pc);
}

void flist_request(PurpleConnection *pc, const gchar* type, JsonObject *object) {
    struct timeval tv;
    unsigned char mask[4];
    unsigned int mask_int;
    unsigned long long payload_len;
    unsigned char finNopcode;
    unsigned long long payload_len_small;
    unsigned int payload_offset = 6;
    unsigned int len_size;
    ssize_t i;
    unsigned long long frame_size;
    char *data = NULL;
    
    // Get the account itself.
    FListAccount *fla = pc->proto_data;
    
    gsize json_len;
    gchar *json_text = NULL;
    gsize sent;
    GString *to_write_str = g_string_new(NULL);
    gchar *to_write = NULL;
    
    // Put in the request type and the space.
    g_string_append(to_write_str, type);
    g_string_append(to_write_str, " ");
    
    if(fla->connection_status == FLIST_HANDSHAKE)
    {
        purple_debug_error("flist", "Attempted to send request during handshake!");
        goto cleanup;
    }else if(fla->connection_status != FLIST_ONLINE && 0 != strcmp(type,"IDN"))
    {
        purple_debug_error("flist", "Attempted to send request before completion of login!");
        goto cleanup;
    }
    
    // Check if we have a JSON object to encode.
    if(object) {
        JsonNode *root = json_node_new(JSON_NODE_OBJECT);
        JsonGenerator *gen = json_generator_new();
        json_node_set_object(root, object);
        json_generator_set_root(gen, root);
        json_text = json_generator_to_data(gen, &json_len);
        g_string_append(to_write_str, json_text);
        g_free(json_text);
        g_object_unref(gen);
        json_node_free(root);
    }
    // Get the payload!
    to_write = g_string_free(to_write_str, FALSE);
    
    // Seed RNG
    gettimeofday(&tv, NULL);
    srand(tv.tv_usec * tv.tv_sec);
    
    // Get mask?
    mask_int = rand();
    memcpy(mask, &mask_int, 4);
    
    // length of payload.
    payload_len = strlen(to_write);
    
    // Everything that follows here is weird technical stuff from the actual
    // libwsclient source. God help us all if this needs to be examined at
    // some point.
    
    finNopcode = 0x81; //FIN and text opcode.
    if(payload_len <= 125) {
        frame_size = 6 + payload_len;
        payload_len_small = payload_len;
        
    } else if(payload_len > 125 && payload_len <= 0xffff) {
        frame_size = 8 + payload_len;
        payload_len_small = 126;
        payload_offset += 2;
    } else if(payload_len > 0xffff && payload_len <= 0xffffffffffffffffLL) {
        frame_size = 14 + payload_len;
        payload_len_small = 127;
        payload_offset += 8;
    } else {
        // HUGE PAYLOAD BRUH
        purple_debug_error("flist", "JSON Payload too large!");
        purple_debug_error("flist", "JSON: %s", to_write);
        return;
    }
    data = (char *)malloc(frame_size);
    memset(data, 0, frame_size);
    *data = finNopcode;
    *(data+1) = payload_len_small | 0x80; //payload length with mask bit on
    if(payload_len_small == 126) {
        payload_len &= 0xffff;
        len_size = 2;
        for(i = 0; i < len_size; i++) {
            *(data+2+i) = *((char *)&payload_len+(len_size-i-1));
        }
    }
    if(payload_len_small == 127) {
        payload_len &= 0xffffffffffffffffLL;
        len_size = 8;
        for(i = 0; i < len_size; i++) {
            *(data+2+i) = *((char *)&payload_len+(len_size-i-1));
        }
    }
    for(i=0;i<4;i++)
        *(data+(payload_offset-4)+i) = mask[i];
    
    memcpy(data+payload_offset, to_write, strlen(to_write));
    for(i=0;i<strlen(to_write);i++)
        *(data+payload_offset+i) ^= mask[i % 4] & 0xff;
    sent = 0;
    i = 0;
    
    // While we've got data to send and no errors
    while(sent < frame_size && i >= 0) {
        i = purple_ssl_write(fla->gsc, data+sent, frame_size - sent);
        sent += i;
    }
    
    // If there's an error, disconnect.
    if(i < 0) {
        printf("type: %s", type);
        purple_connection_error_reason(pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "Failed to send outbound frames.");
    }
cleanup:
    if(data)
        free(data);
    g_free(to_write);
}

static gboolean flist_recv_ssl(PurpleConnection *pc, PurpleSslConnection *gsc) {
    FListAccount *fla = pc->proto_data;
    gchar buf[HELPER_RECV_BUF_SIZE];
    gssize len;
    
    len = purple_ssl_read(gsc, buf, sizeof(buf) - 1);
    if(len <= 0) {
        if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) return FALSE; //try again later
        //TODO: better error reporting
        purple_connection_error_reason(pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "The secured connection has failed.");
        return FALSE;
    }
    buf[len] = '\0';
    fla->rx_buf = g_realloc(fla->rx_buf, fla->rx_len + len + 1);
    memcpy(fla->rx_buf + fla->rx_len, buf, len + 1);
    fla->rx_len += len;
    return TRUE;
}

// Basically destroys the chain of frames
void ws_cleanup_frames(ws_frame *first) {
    ws_frame *this = NULL;
    ws_frame *next = first;
    while(next != NULL) {
        this = next;
        next = this->next_frame;
        if(this->rawdata != NULL) {
            free(this->rawdata);
        }
        free(this);
    }
}

// Checks if a frame is complete (?)
int ws_complete_frame(PurpleConnection *pc, ws_frame *frame) {
    int payload_len_short, i;
    unsigned long long payload_len = 0;
    if(frame->rawdata_idx < 2) {
        return 0;
    }
    frame->fin = (*(frame->rawdata) & 0x80) == 0x80 ? 1 : 0;
    frame->opcode = *(frame->rawdata) & 0x0f;
    frame->payload_offset = 2;
    if((*(frame->rawdata+1) & 0x80) != 0x0) {
        // No clue what the hell this means
        purple_debug_error("flist", "Received masked frame from server");
        purple_connection_error_reason(pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "Received masked frame from server.");
        return 0;
    }
    payload_len_short = *(frame->rawdata+1) & 0x7f;
    switch(payload_len_short) {
        case 126:
            if(frame->rawdata_idx < 4) {
                return 0;
            }
            for(i = 0; i < 2; i++) {
                memcpy((void *)&payload_len+i, frame->rawdata+3-i, 1);
            }
            frame->payload_offset += 2;
            frame->payload_len = payload_len;
            break;
        case 127:
            if(frame->rawdata_idx < 10) {
                return 0;
            }
            for(i = 0; i < 8; i++) {
                memcpy((void *)&payload_len+i, frame->rawdata+9-i, 1);
            }
            frame->payload_offset += 8;
            frame->payload_len = payload_len;
            break;
        default:
            frame->payload_len = payload_len_short;
            break;
            
    }
    if(frame->rawdata_idx < frame->payload_offset + frame->payload_len) {
        return 0;
    }
    return 1;
}

// Control frames are a thing, but really, this could probably be an empty function and still work
// The only control frame there is isn't used by F-List, and the function makes note of that.
static gboolean ws_handle_control_frame(PurpleConnection *pc, ws_frame *ctl_frame) {
    ws_frame *ptr = NULL;
    switch(ctl_frame->opcode) {
        case 0x8:
            purple_connection_error_reason(pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "Server sent close packet; This is outside the F-chat protocol spec!");
            break;
        default:
            purple_debug_info("flist", "Unhandled control frame received.  Opcode: %d\n", ctl_frame->opcode);
            break;
    }
    
    ptr = ctl_frame->prev_frame; //This very well may be a NULL pointer, but just in case we preserve it.
    free(ctl_frame->rawdata);
    memset(ctl_frame, 0, sizeof(ws_frame));
    ctl_frame->prev_frame = ptr;
    ctl_frame->rawdata = (char *)malloc(FRAME_CHUNK_LENGTH);
    memset(ctl_frame->rawdata, 0, FRAME_CHUNK_LENGTH);
    return TRUE;
}

// This actually handles the payload from an incoming packet
static gboolean ws_dispatch_message(PurpleConnection *pc, ws_frame *current) {
    unsigned long long message_payload_len, message_offset;
    int message_opcode;
    char *message_payload;
    ws_frame *first = NULL;
    ws_message *msg = NULL;
    JsonParser *parser = NULL;
    JsonNode *root = NULL;
    JsonObject *object = NULL;
    GError *err = NULL;
    FListAccount *fla = pc->proto_data;
    gboolean ret = FALSE;
    
    // Null frame????
    if(current == NULL) {
        purple_debug_error("flist", "Null frame passed to dispatch");
        return ret;
    }
    // Get the actual payload shit all loaded
    message_offset = 0;
    message_payload_len = current->payload_len;
    for(;current->prev_frame != NULL;current = current->prev_frame) {
        message_payload_len += current->payload_len;
    }
    first = current;
    message_opcode = current->opcode;
    message_payload = (char *)malloc(message_payload_len + 1);
    memset(message_payload, 0, message_payload_len + 1);
    for(;current != NULL; current = current->next_frame) {
        memcpy(message_payload + message_offset, current->rawdata + current->payload_offset, current->payload_len);
        message_offset += current->payload_len;
    }
    
    // Got it (?)
    // Clean up the frames
    ws_cleanup_frames(first);
    msg = (ws_message *)malloc(sizeof(ws_message));
    memset(msg, 0, sizeof(ws_message));
    msg->opcode = message_opcode;
    msg->payload_len = message_offset;
    msg->payload = message_payload;
    
    // Technically we don't need the msg data structure but eh
    gchar *start = msg->payload;
    
    // Get the Command Code
    gchar* code = g_strndup(msg->payload, 3);
    purple_debug_info("flist", "Received Packet. Code: %s\n", code);
    
    // If it's NOT a ping (aka it has JSON), get the JSON object.
    if(strcmp(code,"PIN") != 0)
    {
        start += 4;
        parser = json_parser_new();
        json_parser_load_from_data(parser, start, (gsize) msg->payload_len - 4, &err);
        
        if(fla->debug_mode) {
            gchar *full_packet = g_strndup(start, (gsize) msg->payload_len);
            purple_debug_info(FLIST_DEBUG, "JSON Received: %s\n", full_packet);
            g_free(full_packet);
        }
        
        if(err) { /* not valid json */
            purple_connection_error_reason(pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "Invalid WebSocket data (expecting JSON).");
            purple_debug_info(FLIST_DEBUG, "ERROR: %s\n", err->message);
            g_error_free(err);
            goto cleanup;
        }
        root = json_parser_get_root(parser);
        if(json_node_get_node_type(root) != JSON_NODE_OBJECT) {
            purple_connection_error_reason(pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "Invalid WebSocket data (JSON not an object).");
            goto cleanup;
        }
        object = json_node_get_object(root);
    }
    // Got the code (and possible JSON), call the callback function and clean up!
    ret = TRUE;
    flist_callback(pc, code, object);
    
cleanup:
    if(parser) g_object_unref(parser);
    free(msg->payload);
    free(msg);
    return ret;
}

// Since not every recv is guaranteed to return a frame, we piece it
// together from the buffer (i think)
static gboolean flist_handle_input(PurpleConnection *pc) {
    FListAccount *fla = pc->proto_data;
    g_return_val_if_fail(fla, FALSE);
    gboolean ret = FALSE;
    
    if(fla->rx_len == 0) return FALSE; //nothing to read here!
    
    // We build frames, 1 char at a time!
    char c;
    
    // The shit below is basically reconstructing frames as far as I can tell.
    // More blackbox voodoo for all I know
    for( int i = 0; i < fla->rx_len; i++ )
    {
        c = fla->rx_buf[i];
        ws_frame *current = NULL, *new = NULL;
        unsigned char payload_len_short;
        if(fla->current_frame == NULL) {
            fla->current_frame = (ws_frame *)malloc(sizeof(ws_frame));
            memset(fla->current_frame, 0, sizeof(ws_frame));
            fla->current_frame->payload_len = -1;
            fla->current_frame->rawdata_sz = FRAME_CHUNK_LENGTH;
            fla->current_frame->rawdata = (char *)malloc(fla->current_frame->rawdata_sz);
            memset(fla->current_frame->rawdata, 0, fla->current_frame->rawdata_sz);
        }
        current = fla->current_frame;
        if(current->rawdata_idx >= current->rawdata_sz) {
            current->rawdata_sz += FRAME_CHUNK_LENGTH;
            current->rawdata = (char *)realloc(current->rawdata, current->rawdata_sz);
            memset(current->rawdata + current->rawdata_idx, 0, current->rawdata_sz - current->rawdata_idx);
        }
        *(current->rawdata + current->rawdata_idx++) = c;
        if(ws_complete_frame(pc, current) == 1) {
            if(current->fin == 1) {
                //is control frame
                if((current->opcode & 0x08) == 0x08) {
                    // Got a control frame
                    ret = ws_handle_control_frame(pc, current);
                } else {
                    // Got a regular frame.
                    ret = ws_dispatch_message(pc, current);
                    fla->current_frame = NULL;
                }
            } else {
                new = (ws_frame *)malloc(sizeof(ws_frame));
                memset(new, 0, sizeof(ws_frame));
                new->payload_len = -1;
                new->rawdata = (char *)malloc(FRAME_CHUNK_LENGTH);
                memset(new->rawdata, 0, FRAME_CHUNK_LENGTH);
                new->prev_frame = current;
                current->next_frame = new;
                fla->current_frame = new;
            }
        }
    }
cleanup:
    fla->rx_len = 0;
    return ret;
}

static gboolean flist_handle_handshake(PurpleConnection *pc) {
    char pre_encode[256];
    char sha1bytes[20];
    char expected_base64[512];
    char *p = NULL, *rcv = NULL, *tok = NULL;
    const char *UUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    memset(pre_encode, 0, 256);
    FListAccount *fla = pc->proto_data;
    
    // Okay, we have our base64 data and the UUID, concat them
    snprintf(pre_encode, 256, "%s%s", fla->b64data, UUID);
    
    // SHA1 sum the magic data
    SHA1(pre_encode, strlen(pre_encode), sha1bytes);
    
    // B64 it
    base64_encode(sha1bytes, 20, expected_base64, 512);
    
    // And now that we have the expected key, time to read in the headers.
    gchar *last = fla->rx_buf;
    rcv = (char *)malloc(strlen(fla->rx_buf)+1);
    memset(rcv, 0, strlen(fla->rx_buf)+1);
    strncpy(rcv, fla->rx_buf, strlen(fla->rx_buf));
    
    //
    int hasUpgrade = 0, hasConnection = 0, hasAccept = 0;
    for(tok = strtok(rcv, "\r\n"); tok != NULL; tok = strtok(NULL, "\r\n")) {
        if(*tok == 'H' && *(tok+1) == 'T' && *(tok+2) == 'T' && *(tok+3) == 'P') {
            p = strchr(tok, ' ');
            p = strchr(p+1, ' ');
            *p = '\0';
            if(strcmp(tok, "HTTP/1.1 101") != 0 && strcmp(tok, "HTTP/1.0 101") != 0) {
                //Fail
                purple_debug_error("flist", "No valid HTTP header.");
                return FALSE;
            }
        } else {
            p = strchr(tok, ' ');
            *p = '\0';
            if(strcmp(tok, "Upgrade:") == 0) {
                if(strcasecmp(p+1, "websocket") == 0) {
                    hasUpgrade = 1;
                }else{
                    purple_debug_error("flist", "Invalid upgrade in websocket handshake.");
                    return FALSE;
                }
            }
            if(strcmp(tok, "Connection:") == 0) {
                if(strcasecmp(p+1, "Upgrade") == 0) {
                    hasConnection = 1;
                }else{
                    purple_debug_error("flist", "Invalid connection in websocket handshake.");
                    return FALSE;
                }
            }
            if(strcmp(tok, "Sec-WebSocket-Accept:") == 0) {
                if(strcmp(p+1, expected_base64) == 0) {
                    hasAccept = 1;
                }else{
                    purple_debug_error("flist", "Invalid Accept Key in websocket handshake.");
                    return FALSE;
                }
            }
        }
    }
    if(hasUpgrade != 1)
    {
        purple_debug_error("flist", "No upgrade in websocket handshake.");
        purple_connection_error_reason(fla->pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "No upgrade in websocket handshake.");
    }else if(hasConnection != 1)
    {
        purple_debug_error("flist", "No connection in websocket handshake.");
        purple_connection_error_reason(fla->pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "No connection in websocket handshake.");
        return FALSE;
    }else if(hasAccept != 1)
    {
        purple_debug_error("flist", "No accept key in websocket handshake.");
        purple_connection_error_reason(fla->pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "No accept key in websocket handshake.");
        return FALSE;
    }
    purple_debug_info("flist", "Identifying...");
    fla->rx_len = 0;
    fla->connection_status = FLIST_IDENTIFY;
    purple_connection_update_progress(fla->pc, "Identifying...", 3, 5);
    flist_IDN(pc);
    return TRUE;
}
void flist_process_ssl(gpointer data, PurpleSslConnection *gsc, PurpleInputCondition cond) {
    PurpleConnection *pc = data;
    FListAccount *fla = pc->proto_data;
	if(!PURPLE_CONNECTION_IS_VALID(pc)) {
        return;
	}
    if(cond == PURPLE_INPUT_READ) {
        if(!flist_recv_ssl(pc, gsc)) return;
        if(fla->connection_status == FLIST_HANDSHAKE && !flist_handle_handshake(pc)) return;
        while(flist_handle_input(pc));
    }
}

void flist_IDN(PurpleConnection *pc) {
    FListAccount *fla = pc->proto_data;
    JsonObject *object;
    const gchar *ticket = flist_get_ticket(fla);
    
    object = json_object_new();
    if(ticket) {
        json_object_set_string_member(object, "method", "ticket");
        json_object_set_string_member(object, "ticket", ticket);
        json_object_set_string_member(object, "account", fla->username);
        json_object_set_string_member(object, "cname", FLIST_CLIENT_NAME);
        json_object_set_string_member(object, "cversion", FLIST_PLUGIN_VERSION);
    }
    json_object_set_string_member(object, "character", fla->character);
    flist_request(pc, "IDN", object);
    json_object_unref(object);
}

static void flist_connected_ssl(gpointer data, PurpleSslConnection *gsc,
                                PurpleInputCondition cond) {
    FListAccount *fla = data;
    struct timeval tv;
    
	if(!PURPLE_CONNECTION_IS_VALID(fla->pc)) {
		purple_ssl_close(gsc);
		g_return_if_reached();
	}
    
    fla->gsc = gsc;
    purple_debug_info("flist", "Opened secure connection, initiating handshake...");
    purple_connection_update_progress(fla->pc, "Sending opening handshake...", 2, 5);

    purple_ssl_input_add(gsc, flist_process_ssl, fla->pc);
    fla->ping_timeout_handle = purple_timeout_add_seconds(FLIST_TIMEOUT, flist_disconnect_cb, fla->pc);
    GString *headers_str = g_string_new(NULL);
    gchar *headers;
    ssize_t len;
    g_string_append(headers_str, "GET / HTTP/1.1\r\n");
    g_string_append(headers_str, "Upgrade: WebSocket\r\n");
    g_string_append(headers_str, "Connection: Upgrade\r\n");
    g_string_append_printf(headers_str, "Host: %s:%d\r\n", fla->server_address, fla->server_port);
    g_string_append(headers_str, "Origin: https://www.f-list.net\r\n");
    
    // Generate random data, b64 it
    guchar nonce[16];
    gettimeofday(&tv, NULL);
    srand(tv.tv_usec * tv.tv_sec);
    for (int i = 0; i < 16; i++) {
        nonce[i] = rand() % 256;
    }
    // Store b64 data
    fla->b64data = g_base64_encode(nonce, 16);
    g_string_append(headers_str, "Sec-WebSocket-Key: ");
    g_string_append(headers_str, fla->b64data);
    g_string_append(headers_str, "\r\n");
    g_string_append(headers_str, "Sec-WebSocket-Version: 13\r\n\r\n");
    headers = g_string_free(headers_str, FALSE);
    
    // Got the headers, send them and wait for the return.
    len = purple_ssl_write(fla->gsc, headers, strlen(headers)); //TODO: check return value
    purple_debug_info("flist", "Sent handshake...");
    fla->connection_status = FLIST_HANDSHAKE;
    g_free(headers);
}

void flist_error_ssl(PurpleSslConnection *gsc, PurpleSslErrorType error,
                gpointer data) {
    FListAccount *fla = data;
    // If we're disconnected, nothing to do.
    g_return_if_fail(PURPLE_CONNECTION_IS_VALID(fla->pc));
    fla->gsc = NULL;
    fla->connection_status = FLIST_OFFLINE;
    purple_connection_ssl_error (fla->pc, error);
}

static void flist_receive_ticket(FListWebRequestData *req_data, gpointer data, JsonObject *root, const gchar *error) {
    FListAccount *fla = data;
    const gchar *ticket;
    gboolean first = fla->connection_status == FLIST_OFFLINE;
    
    fla->ticket_request = NULL;
    flist_ticket_timer(fla, FLIST_TICKET_TIMER_TIMEOUT);
    
    if(error) {
        if(first) purple_connection_error_reason(fla->pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, error);
        return;
    }
    
    error = json_object_get_string_member(root, "error");
    if(error && strlen(error)) {
        if(first) purple_connection_error_reason(fla->pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, error);
        return;
    }
    
    ticket = json_object_get_string_member(root, "ticket");
    if(!ticket) {
        if(first) purple_connection_error_reason(fla->pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, "No ticket returned.");
        return;
    }
    
    g_hash_table_insert(ticket_table, g_strdup(fla->username), g_strdup(ticket));
    purple_debug_info("flist", "Login Ticket: %s\n", ticket);
    
    if(first) {
        purple_connection_update_progress(fla->pc, "Opening secure connection...", 1, 5);
        fla->gsc = purple_ssl_connect(fla->pa, fla->server_address, fla->server_port, flist_connected_ssl, flist_error_ssl, fla);
        if(!fla->gsc) {
            purple_connection_error_reason(fla->pc, PURPLE_CONNECTION_ERROR_NETWORK_ERROR, _("Unable to open a secured connection."));
            return;
        }
        fla->connection_status = FLIST_CONNECT;
    }
}

static gboolean flist_ticket_timer_cb(gpointer data) {
    FListAccount *fla = data;
    GHashTable *args = g_hash_table_new_full(g_str_hash, g_str_equal, NULL, g_free);
    g_hash_table_insert(args, "account", g_strdup(fla->username));
    g_hash_table_insert(args, "password", g_strdup(fla->password));
    purple_connection_update_progress(fla->pc, "Getting ticket...", 0, 5);
    fla->ticket_request = flist_web_request(FLIST_TICKET_URL, args, TRUE, flist_receive_ticket, fla); 
    fla->ticket_timer = 0;
    
    g_hash_table_destroy(args);
    
    return FALSE;
}

void flist_ticket_timer(FListAccount *fla, guint timeout) {
    if(fla->ticket_timer) {
        purple_timeout_remove(fla->ticket_timer);
    }
    fla->ticket_timer = purple_timeout_add_seconds(timeout, (GSourceFunc) flist_ticket_timer_cb, fla);
}

void flist_ticket_init() {
    ticket_table = g_hash_table_new_full((GHashFunc) flist_str_hash, (GEqualFunc) flist_str_equal, g_free, g_free);
}
