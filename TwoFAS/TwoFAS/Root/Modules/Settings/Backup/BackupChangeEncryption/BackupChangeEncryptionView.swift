//
//  This file is part of the 2FAS iOS app (https://github.com/twofas/2fas-ios)
//  Copyright © 2025 Two Factor Authentication Service, Inc.
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

import SwiftUI
import Common

struct BackupChangeEncryptionView: View {
    @ObservedObject
    var presenter: BackupChangeEncryptionPresenter
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .center) {
                    VStack(alignment: .center, spacing: Theme.Metrics.standardSpacing) {
                        Form {
                            Section {
                                Text(T.Backup.encryptionSelect)
                                    .font(.body)
                                Picker(selection: $presenter.selectedEncryption) {
                                    ForEach(CloudEncryptionType.allCases, id: \.self) { type in
                                        Text(type.localized)
                                            .tag(type)
                                    }
                                } label: {
                                    EmptyView()
                                }
                                .pickerStyle(.segmented)
                                .tint(Color(Theme.Colors.Fill.theme))
                            } header: {
                                Spacer()
                                    .frame(height: 0)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            
                            if presenter.selectedEncryption == .user {
                                Section(
                                    content: {
                                        passwordInput
                                    },
                                    header: {
                                        presenter.changingPassword ?
                                        Text(verbatim: T.Backup.encryptionChangePassword) :
                                        Text(verbatim: T.Backup.encryptionEnterPassword)
                                    },
                                    footer: {
                                        Text(verbatim: T.Backup.encryptionPasswordDescription)
                                            .font(.caption2)
                                            .minimumScaleFactor(0.8)
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                    .disabled(presenter.isChangingEncryption)
                    .padding(.bottom, Theme.Metrics.doubleMargin)
                    .navigationTitle(T.Backup.encryptionChangeTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                presenter.close()
                            }) {
                                Text(T.Commons.close)
                                    .tint(Color(Theme.Colors.Text.theme))
                            }
                            .disabled(presenter.isChangingEncryption)
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    if presenter.isChangingEncryption {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                            .tint(Color(ThemeColor.theme))
                            .padding(.bottom, Theme.Metrics.doubleMargin)
                    } else {
                        VStack(alignment: .center, spacing: Theme.Metrics.doubleMargin) {
                            if let migrationFailureReason = presenter.migrationFailureReason {
                                Label(
                                    T.Backup.enterPasswordFailure(migrationFailureReason.description),
                                    systemImage: "xmark.circle.fill"
                                )
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(Theme.Colors.Text.theme))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    if !presenter.isChangingEncryption {
                        Button {
                            dismissKeyboard()
                            presenter.applyChange()
                        } label: {
                            Text(verbatim: T.Commons.apply)
                                .frame(maxWidth: .infinity)
                        }
                        .modify {
                            if presenter.changePasswordEnabled {
                                $0.buttonStyle(RoundedFilledButtonStyle())
                            } else {
                                $0.buttonStyle(RoundedFilledInactiveButtonStyle())
                            }
                        }
                        .frame(maxWidth: Theme.Metrics.componentWidth)
                        .padding(.horizontal, Theme.Metrics.doubleMargin)
                        .padding(.bottom, Theme.Metrics.doubleMargin)
                        .disabled(!presenter.changePasswordEnabled)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity)
        .background(Color(Theme.Colors.Fill.background))
        .onAppear {
            presenter.onAppear()
        }
    }
    
    @ViewBuilder
    private var passwordInput: some View {
        VStack(spacing: Theme.Metrics.halfSpacing) {
            SecureField(T.Backup.encryptionEnterPassword, text: $presenter.password)
                .onSubmit {
                    if presenter.changePasswordEnabled {
                        presenter.applyChange()
                    } else {
                        dismissKeyboard()
                    }
                }
            Divider()
                .overlay {
                    Rectangle()
                        .foregroundStyle(!presenter.changePasswordEnabled ?
                                         Color(Theme.Colors.Text.inactive) :
                                            Color(Theme.Colors.Line.primaryLine))
                }
        }
    }
}
