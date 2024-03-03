#include "cli.hpp"

enum protocols
{
	PROTOCOL_EXAMPLE = 0,
	PROTOCOL_COUNT
};

int websocket_callback(struct lws *wsi, enum lws_callback_reasons reason, void *user, \
	void *in, size_t len)
{
	t_game *game = static_cast<t_game *>(lws_context_user(lws_get_context(wsi)));
	(void)len;
	(void)user;

	switch( reason )
	{
		case LWS_CALLBACK_CLIENT_ESTABLISHED:
			game->write_buf = "{\"type\":\"ping\",\"data\":\"connected\"}";
			lws_callback_on_writable(wsi);
			break;

		case LWS_CALLBACK_CLIENT_RECEIVE:
			refresh();
			handle_message(game, (char *)in);
			break;

		case LWS_CALLBACK_CLIENT_WRITEABLE:
		{
			unsigned char buf[LWS_SEND_BUFFER_PRE_PADDING + TX_BUFFER_BYTES + LWS_SEND_BUFFER_POST_PADDING];
			unsigned char *p = &buf[LWS_SEND_BUFFER_PRE_PADDING];
			size_t n = sprintf((char *)p, "%s", game->write_buf.c_str());
			lws_write( wsi, p, n, LWS_WRITE_TEXT );
			game->write_buf.clear();
			break;
		}

		case LWS_CALLBACK_CLIENT_CLOSED:
		case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
			game->web_socket = NULL;
			break;

		default:
			break;
	}

	return 0;
}

static struct lws_protocols protocols[] =
{
    {
        .name                  = "example-protocol", /* Protocol name*/
        .callback              = websocket_callback,   /* Protocol callback */
        .per_session_data_size = 0,                  /* Protocol callback 'userdata' size */
        .rx_buffer_size        = READ_BUFFER,                  /* Receve buffer size (0 = no restriction) */
        .id                    = 0,                  /* Protocol Id (version) (optional) */
        .user                  = NULL,               /* 'User data' ptr, to access in 'protocol callback */
        .tx_packet_size        = 0                   /* Transmission buffer size restriction (0 = no restriction) */
    },
    {NULL, NULL, 0, 0, 0, NULL, 0}
};

int websocket_init(t_game *game)
{
	SSL_CTX *ssl_ctx = NULL;
    SSL_load_error_strings();
    SSL_library_init();
    ssl_ctx = SSL_CTX_new(SSLv23_client_method());

    /* Load SSL certificate and private key */
    if (SSL_CTX_use_certificate_file(ssl_ctx, "./temp.crt", SSL_FILETYPE_PEM) != 1 ||
        SSL_CTX_use_PrivateKey_file(ssl_ctx, "./temp.key", SSL_FILETYPE_PEM) != 1)
    {
		std::cerr << "Error loading certs" << std::endl;
        /* Handle error loading certificate/private key */
        return (1);
    }

	game->web_socket = NULL;
	game->state = connecting;
	game->searching_for = menu;
	game->previous_state = connecting;
	game->first_update = true;
	game->player_id = 0;
	game->msg.clear();
	game->write_buf.clear();
	game->token.clear();
	game->register_status.clear();
	game->login_status.clear();
	game->menu_message.clear();
	game->awaiting_auth = false;
	struct lws_context_creation_info info;
	memset( &info, 0, sizeof(info) );

	info.port = CONTEXT_PORT_NO_LISTEN; /* we do not run any server */
	info.protocols = protocols;
	info.gid = -1;
	info.uid = -1;
	info.ssl_cert_filepath = NULL;
    info.ssl_private_key_filepath = NULL;
    info.options |= LWS_SERVER_OPTION_DO_SSL_GLOBAL_INIT;
    info.ssl_cipher_list = "ECDHE-ECDSA-AES256-GCM-SHA384";
	info.user = game;

	game->context = lws_create_context( &info );
	return (0);
}

void websocket_connect(t_game *game)
{
	while (game->web_socket == NULL)
	{
		struct lws_client_connect_info ccinfo;
		memset(&ccinfo, 0, sizeof(ccinfo));
		
		ccinfo.context = game->context;
		ccinfo.address = "127.0.0.1";
		ccinfo.port = 9001;
		ccinfo.path = "/ws";
		ccinfo.host = lws_canonical_hostname( game->context );
		ccinfo.origin = "origin";
		ccinfo.protocol = protocols[PROTOCOL_EXAMPLE].name;
		ccinfo.ssl_connection = LCCSCF_USE_SSL | LCCSCF_ALLOW_SELFSIGNED | LCCSCF_SKIP_SERVER_CERT_HOSTNAME_CHECK;

		game->web_socket = lws_client_connect_via_info(&ccinfo);
		lws_service(game->context, -1);
	}
}