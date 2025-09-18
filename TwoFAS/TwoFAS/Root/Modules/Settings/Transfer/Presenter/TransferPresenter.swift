//
//  This file is part of the 2FAS iOS app (https://github.com/twofas/2fas-ios)
//  Copyright © 2023 Two Factor Authentication Service, Inc.
//  Contributed by Zbigniew Cisiński. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see <https://www.gnu.org/licenses/>
//

import Foundation

final class TransferPresenter {
    weak var view: TransferViewControlling?
    
    private let flowController: TransferFlowControlling
    let interactor: TransferModuleInteracting
    
    init(flowController: TransferFlowControlling, interactor: TransferModuleInteracting) {
        self.flowController = flowController
        self.interactor = interactor
    }

    func viewWillAppear() {
        reload()
        if !interactor.hasServices {
            view?.lock()
        }
    }
    
    func handleSelection(at indexPath: IndexPath) {
        let menu = buildMenu()
        guard
            let section = menu[safe: indexPath.section],
            let cell = section.cells[safe: indexPath.row]
        else { return }
        
        switch cell.action {
        case .aegis:
            flowController.toAegis()
        case .raivo:
            flowController.toRaivo()
        case .lastPass:
            flowController.toLastPass()
        case .googleAuth:
            flowController.toGoogleAuth()
        case .andOTP:
            flowController.toAndOTP()
        case .authenticatorPro:
            flowController.toAuthenticatorPro()
        case .otpAuthFileImport:
            flowController.toOpenTXTFile()
        case .otpAuthFileExport:
            guard interactor.hasPIN else {
                flowController.toSetupPIN()
                return
            }
            flowController.toSaveOTPAuthFile()
        case .exportQRCodes:
            guard interactor.hasPIN else {
                flowController.toSetupPIN()
                return
            }
            flowController.toExportQRCodes()
        }
    }
    
    func handleBecomeActive() {
        reload()
    }
    
    func handleSaveOTPAuthFile() {
        guard let url = interactor.createOTPAuthCodesFile() else {
            flowController.toError(T.Commons.fileCreationError)
            return
        }
        flowController.toShareOTPAuthFileContents(url) { [weak self] in
            self?.interactor.cleanupTemporaryFiles(urls: [url])
        }
    }
    
    func handleExportQRCodes() {
        view?.exporting()
        Task {
            guard let url = await interactor.createQRCodeFiles() else {
                Task { @MainActor in
                    flowController.toError(T.Commons.fileCreationError)
                    view?.unlock()
                }
                return
            }
            Task { @MainActor in
                flowController.toShareQRCodes(url) { [weak self] in
                    self?.interactor.cleanupTemporaryFiles(urls: [url])
                }
                view?.unlock()
            }
        }
    }
}

private extension TransferPresenter {
    func reload() {
        let menu = buildMenu()
        view?.reload(with: menu)
    }
}
