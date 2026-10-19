import Foundation
import Network

/// Outcome of a single TCP probe.
enum PortProbe {
    case open        // the port accepted a connection
    case closed      // the host refused the connection -> it is up, port closed
    case unreachable // timed out or no route -> treat the host as absent
}

/// A tiny thread-safe "fire once" flag. The first caller to `testAndSet()`
/// wins; everyone after gets `false`.
final class OnceFlag {
    private var fired = false
    private let lock = NSLock()

    func testAndSet() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if fired { return false }
        fired = true
        return true
    }
}

/// Probes individual TCP ports using the Network framework. A `.ready` state
/// means the port is open; an `ECONNREFUSED`/`ECONNRESET` means the host is
/// alive but the port is closed; anything else (including a timeout) is
/// treated as unreachable.
actor PortScanner {
    private let queue = DispatchQueue(label: "com.netscan.portscanner", attributes: .concurrent)

    func probe(host: String, port: UInt16, timeout: TimeInterval = 1.2) async -> PortProbe {
        await withCheckedContinuation { (continuation: CheckedContinuation<PortProbe, Never>) in
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                continuation.resume(returning: .unreachable)
                return
            }

            let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
            let once = OnceFlag()

            func finish(_ result: PortProbe) {
                guard once.testAndSet() else { return }
                connection.stateUpdateHandler = nil
                connection.cancel()
                continuation.resume(returning: result)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    finish(.open)
                case .waiting(let error), .failed(let error):
                    finish(Self.classify(error))
                default:
                    break
                }
            }

            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + timeout) {
                finish(.unreachable)
            }
        }
    }

    private static func classify(_ error: NWError) -> PortProbe {
        if case let .posix(code) = error {
            switch code {
            case .ECONNREFUSED, .ECONNRESET:
                return .closed      // something is there, it just isn't listening
            default:
                return .unreachable
            }
        }
        return .unreachable
    }
}
