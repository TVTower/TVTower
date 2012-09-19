#include <string.h>
#include <net/if.h>
#include <sys/socket.h>
#include <netinet/in.h>
#ifdef __APPLE__
# include <sys/sockio.h>
#else
# include <linux/sockios.h>
#endif

#define MAX_INTERFACES 64

#define TRUE 1
#define FALSE 0

int GetNetworkAdapter(char *Device, char MAC[6], int *Address, int *Netmask, int *Broadcast)
{
	int            Socket;
	struct ifreq  *pInterface;
	struct ifconf  Config;
	char           Buffer[MAX_INTERFACES*sizeof(struct ifreq)];
	int            Count, I;

	Socket = socket(AF_INET, SOCK_DGRAM, 0);
	if(Socket == -1) return FALSE;

	Config.ifc_len = sizeof(Buffer);
	Config.ifc_buf = Buffer;
	if(ioctl(Socket, SIOCGIFCONF, &Config) != 0)
	{
		close(Socket);
		return FALSE;
	}

	Count = Config.ifc_len/sizeof(struct ifreq);
	pInterface = Config.ifc_req;

	for(I = 0; I < Count; I++)
	{
		if(pInterface->ifr_addr.sa_family == AF_INET &&
		   strncmp(pInterface->ifr_name, "eth", 3) == 0)
		{
			strcpy(Device, pInterface->ifr_name);
			*Address = ntohl(((struct sockaddr_in *)&pInterface->ifr_addr)->sin_addr.s_addr);
			ioctl(Socket, SIOCGIFHWADDR, pInterface);
			memcpy(MAC, &pInterface->ifr_hwaddr.sa_data, 6);
			ioctl(Socket, SIOCGIFNETMASK, pInterface);
			*Netmask = ntohl(((struct sockaddr_in *)&pInterface->ifr_netmask)->sin_addr.s_addr);
			*Broadcast = *Address | ~(*Netmask);

			close(Socket);
			return TRUE;
		}

		pInterface++;
	}

	close(Socket);
	return FALSE;
}