#include <windows.h>
#include <iptypes.h>
#include <ipifcons.h>
#include <iphlpapi.h>
#include <string.h>

int GetNetworkAdapter(char *Device, char MAC[6], int *Address, int *Netmask, int *Broadcast)
{
	PIP_ADAPTER_INFO pAdapterInfo;
	PIP_ADAPTER_INFO pAdapter;
	ULONG            BufferSize;

	pAdapterInfo = (PIP_ADAPTER_INFO) malloc(sizeof(IP_ADAPTER_INFO));
	pAdapter = NULL;
	BufferSize = sizeof(IP_ADAPTER_INFO);

	if(GetAdaptersInfo(pAdapterInfo, &BufferSize) == ERROR_BUFFER_OVERFLOW)
	{
		free(pAdapterInfo);
		pAdapterInfo = (PIP_ADAPTER_INFO) malloc(BufferSize);
		if(!pAdapterInfo) return FALSE;
	}

	if(GetAdaptersInfo(pAdapterInfo, &BufferSize) != NO_ERROR)
	{
		free(pAdapterInfo);
		return FALSE;
	}

	pAdapter = pAdapterInfo;
	while(pAdapter)
	{
		if(pAdapter->Type == MIB_IF_TYPE_ETHERNET) break;
		pAdapter = pAdapter->Next;
	}
	if(!pAdapter)
	{
		free(pAdapterInfo);
		return FALSE;
	}

	strcpy(Device, pAdapter->Description);
	if(pAdapter->AddressLength != 6) {
		ZeroMemory(MAC, 6);
	} else {
		memcpy(MAC, pAdapter->Address, 6);
	}

	*Address   = ntohl(inet_addr(pAdapter->IpAddressList.IpAddress.String));
	*Netmask   = ntohl(inet_addr(pAdapter->IpAddressList.IpMask.String));
	*Broadcast = *Address | ~(*Netmask);

	free(pAdapterInfo);
	return TRUE;
}