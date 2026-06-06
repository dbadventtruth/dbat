#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/socket.h>

#ifdef __cplusplus
extern "C" {
#endif

struct net_connection;
struct descriptor_data;

typedef struct descriptor_data *(*net_accept_descriptor_fn)(socklen_t fd, const char *host, struct net_connection *conn);

bool net_listener_adopt(socklen_t fd);
int net_listener_open(uint16_t port);
void net_listener_close(void);
void net_accept_callback_set(net_accept_descriptor_fn callback);

struct net_connection *net_connection_create(socklen_t fd);
void net_connection_destroy(struct net_connection *conn);
socklen_t net_connection_fd(const struct net_connection *conn);
void net_connection_descriptor_set(struct net_connection *conn, struct descriptor_data *desc);
struct descriptor_data *net_connection_descriptor(const struct net_connection *conn);
bool net_connection_host_set(struct net_connection *conn, const char *host);
const char *net_connection_host(const struct net_connection *conn);

bool net_connection_send(struct net_connection *conn, const char *bytes, size_t len);
bool net_connection_send_fd(socklen_t fd, const char *bytes, size_t len);
char *net_connection_pop_line(struct net_connection *conn);
void net_connection_free_line(char *line);

int net_accept_all_pending(void);
int net_read_all_pending(void);
int net_flush_all_outputs(void);
int net_wait(int timeout_ms);

bool net_copyover_dump(const char *path);
bool net_copyover_recover(const char *path);

#ifdef __cplusplus
}
#endif
