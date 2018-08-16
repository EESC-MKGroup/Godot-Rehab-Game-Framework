extends Node

const SERVER_PORT = 50004

const PACKET_SIZE = 512
const PACKET_HEADER_LENGTH = 4

const TYPE_VALUES_NUMBER = 4
const VALUE_HEADER_SIZE = 2
const VALUE_DATA_SIZE = TYPE_VALUES_NUMBER * 4
const VALUE_BLOCK_SIZE = VALUE_HEADER_SIZE + VALUE_DATA_SIZE
const VALUE_OID_OFFSET = 0
const VALUE_INDEX_OFFSET = 1

var peer = NetworkedMultiplayerENet.new()

var networkDelay = 0.0

var input_buffer = StreamPeerBuffer.new()
var output_buffer = StreamPeerBuffer.new()

var remote_values = {}
var local_values = {}

var updated_local_keys = []

var input_delays = {}

func _ready():
	input_buffer.resize( BUFFER_SIZE )
	output_buffer.resize( BUFFER_SIZE )

func shutdown():
	peer.disconnect()

	public abstract void Connect();

	public void SetLocalValue( byte objectID, byte valueType, int valueIndex, float value ) 
	{
		KeyValuePair<byte,byte> localKey = new KeyValuePair<byte,byte>( objectID, valueType );

		if( !localValues.ContainsKey( localKey ) ) localValues[ localKey ] = new float[ TYPE_VALUES_NUMBER ];

		bool isLocalKeyUpdated = false;
		if( Mathf.Approximately( localValues[ localKey ][ valueIndex ], 0.0f ) ) isLocalKeyUpdated = true;
		else if( Mathf.Abs( ( localValues[ localKey ][ valueIndex ] - value ) / localValues[ localKey ][ valueIndex ] ) > 0.01f ) isLocalKeyUpdated = true;
		
		if( isLocalKeyUpdated )
		{
			//Debug.Log( "updating value [" + localKey.ToString() + "," + valueIndex.ToString() + "]: " + localValues[ localKey ][ valueIndex ].ToString() + " -> " + value.ToString() );
			localValues[ localKey ][ valueIndex ] = value;
			updatedLocalKeys.Add( localKey );
		}
	}

	public float GetRemoteValue( byte objectID, byte valueType, int valueIndex )
	{
		KeyValuePair<byte,byte> remoteKey = new KeyValuePair<byte,byte>( objectID, valueType );

		float remoteValue = 0.0f;

		if( remoteValues.ContainsKey( remoteKey ) ) 
		{
			remoteValue = remoteValues[ remoteKey ][ valueIndex ];
			remoteValues[ remoteKey ][ valueIndex ] = 0.0f;
		}

		return remoteValue;
	}

	public void UpdateData( float updateTime )
	{
		int outputMessageLength = PACKET_HEADER_LENGTH;

		if( socketID == -1 ) return;

		foreach( KeyValuePair<byte,byte> localKey in updatedLocalKeys ) 
		{
			outputBuffer[ outputMessageLength + VALUE_OID_OFFSET ] = localKey.Key;
			outputBuffer[ outputMessageLength + VALUE_INDEX_OFFSET ] = localKey.Value;
			outputMessageLength += VALUE_HEADER_SIZE;

			for( int valueIndex = 0; valueIndex < TYPE_VALUES_NUMBER; valueIndex++ ) 
			{
				int dataOffset = outputMessageLength + valueIndex * sizeof(float);
				Buffer.BlockCopy( BitConverter.GetBytes( localValues[ localKey ][ valueIndex ] ), 0, outputBuffer, dataOffset, sizeof(float) );
			}

			outputMessageLength += VALUE_DATA_SIZE;
		}
			
		if( updatedLocalKeys.Count > 0 ) 
		{
			Buffer.BlockCopy( BitConverter.GetBytes( outputMessageLength ), 0, outputBuffer, 0, PACKET_HEADER_LENGTH );
			//Debug.Log( "sending " + updatedLocalKeys.Count.ToString() + " blocks (" + BitConverter.ToInt32( outputBuffer, 0 ).ToString() + " bytes)" );
			SendUpdateMessage();
		}

		updatedLocalKeys.Clear();

		if( ReceiveUpdateMessage() )
		{
			int inputMessageLength = Math.Min( BitConverter.ToInt32( inputBuffer, 0 ), PACKET_SIZE - VALUE_BLOCK_SIZE );
			Debug.Log( "receiving " + inputMessageLength.ToString() + " bytes" );
			for( int blockOffset = PACKET_HEADER_LENGTH; blockOffset < inputMessageLength; blockOffset += VALUE_BLOCK_SIZE )
			{
				byte objectID = inputBuffer[ blockOffset + VALUE_OID_OFFSET ];
				byte axisIndex = inputBuffer[ blockOffset + VALUE_INDEX_OFFSET ];
				KeyValuePair<byte,byte> remoteKey = new KeyValuePair<byte,byte>( objectID, axisIndex );
				Debug.Log( "Received values for key " + remoteKey.ToString() );
				if( !remoteValues.ContainsKey( remoteKey ) ) remoteValues[ remoteKey ] = new float[ TYPE_VALUES_NUMBER ];

				for( int valueIndex = 0; valueIndex < TYPE_VALUES_NUMBER; valueIndex++ ) 
				{
					int dataOffset = blockOffset + VALUE_HEADER_SIZE + valueIndex * sizeof(float);
					remoteValues[ remoteKey ][ valueIndex ] = BitConverter.ToSingle( inputBuffer, dataOffset );
				}

				inputDelays[ objectID ] = networkDelay;
			}
		}
	}

	protected abstract void SendUpdateMessage();

	protected abstract bool ReceiveUpdateMessage();

	public float GetNetworkDelay( byte objectID ) 
	{ 
		if( inputDelays.ContainsKey( objectID ) ) return inputDelays[ objectID ];

		return 0.0f; 
	}